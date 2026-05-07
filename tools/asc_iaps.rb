#!/usr/bin/env ruby
# Idempotent ASC IAP / Subscription provisioning for Prune.
#
# Hits the App Store Connect REST API directly (v1 subscriptions/subscriptionGroups,
# v2 inAppPurchases) because the Spaceship version bundled with fastlane 2.233.0
# does not expose model classes for those resources. Auth uses the same .p8 key
# the Fastfile already reads.
#
# Run via fastlane lane :iaps, or directly:
#   ruby -I /opt/homebrew/Cellar/fastlane/2.233.0/libexec/gems/fastlane-2.233.0/spaceship/lib \
#        tools/asc_iaps.rb
#
# Idempotent: re-runs only create what's missing. Safe to re-run after partial failure.

require 'spaceship'
require 'uri'
require 'digest'

module ASCIaps
  APP_ID         = "6757726140".freeze
  ASC_KEY_ID     = "PVM59TXT82".freeze
  ASC_ISSUER_ID  = "b20319f4-0561-4b65-99f3-ef97d3959ee6".freeze
  ASC_KEY_PATH   = File.expand_path("~/.appstoreconnect/private_keys/AuthKey_#{ASC_KEY_ID}.p8").freeze

  GROUP_REF_NAME = "Prune Pro".freeze
  GROUP_LOC_NAME = "Pruned Pro".freeze

  REVIEW_NOTE = (
    "Pruned Pro unlocks unlimited swipes plus smart feeds (screenshots, " \
    "selfies, videos, favorites, custom date ranges). On the home screen, " \
    "tap any feed marked with a crown to see the paywall, then choose a tier."
  ).freeze

  REVIEW_SCREENSHOT_PATH = File.expand_path("../screenshots/appstore/05-paywall.png", __dir__).freeze

  TERRITORY = "USA".freeze

  SUBSCRIPTIONS = [
    {
      product_id:  "prune_weekly",
      name:        "Weekly",
      description: "3-day trial, then $6.99/wk for unlimited swipes.",
      period:      "ONE_WEEK",
      group_level: 1,
      price:       "6.99",
      intro:       { mode: "FREE_TRIAL", duration: "THREE_DAYS", price: nil }
    },
    {
      product_id:  "prune_monthly",
      name:        "Monthly",
      description: "Monthly access to Pruned Pro features.",
      period:      "ONE_MONTH",
      group_level: 2,
      price:       "4.99",
      intro:       nil
    },
    {
      product_id:  "prune_yearly",
      name:        "Yearly",
      description: "Yearly access to Pruned Pro. Best value.",
      period:      "ONE_YEAR",
      group_level: 3,
      price:       "39.99",
      intro:       { mode: "FREE_TRIAL", duration: "ONE_WEEK", price: nil }
    }
  ].freeze

  LIFETIME = {
    product_id:  "prune_lifetime",
    name:        "Lifetime",
    description: "Unlock all Pruned Pro features forever.",
    price:       "99.99"
  }.freeze

  module_function

  def client
    token = Spaceship::ConnectAPI::Token.create(
      key_id:    ASC_KEY_ID,
      issuer_id: ASC_ISSUER_ID,
      filepath:  ASC_KEY_PATH
    )
    Spaceship::ConnectAPI::APIClient.new(token: token)
  end

  # Gracefully GET; if the resource does not exist (404) return nil.
  def safe_get(c, path, params = {})
    c.get(path, params).body
  rescue Spaceship::UnexpectedResponse, Spaceship::AccessForbidden => e
    msg = e.message
    return nil if msg.include?("404") || msg =~ /NOT_FOUND/i || msg.include?("does not exist")
    raise
  end

  # Walk paginated GET endpoints, returning the merged data array.
  def get_all(c, path, params = {})
    items = []
    cursor = nil
    page_param = params.dup
    loop do
      page_param[:cursor] = cursor if cursor
      body = c.get(path, page_param).body
      items.concat(Array(body["data"]))
      next_link = body.dig("links", "next")
      break if next_link.nil?
      next_cursor = URI.decode_www_form(URI.parse(next_link).query.to_s).to_h["cursor"]
      break if next_cursor.nil? || next_cursor == cursor
      cursor = next_cursor
    end
    items
  end

  # ---------- Subscription Group ----------

  def find_or_create_group(c)
    existing = get_all(c, "v1/apps/#{APP_ID}/subscriptionGroups",
                       "fields[subscriptionGroups]" => "referenceName")
    grp = existing.find { |g| g.dig("attributes", "referenceName") == GROUP_REF_NAME }
    if grp
      puts "  ✓ subscription group exists: #{grp['id']} (#{GROUP_REF_NAME})"
      group_id = grp["id"]
    else
      body = {
        data: {
          type: "subscriptionGroups",
          attributes: { referenceName: GROUP_REF_NAME },
          relationships: { app: { data: { type: "apps", id: APP_ID } } }
        }
      }
      group_id = c.post("v1/subscriptionGroups", body).body.dig("data", "id")
      puts "  + created subscription group: #{group_id} (#{GROUP_REF_NAME})"
    end

    ensure_group_localization(c, group_id)
    group_id
  end

  def ensure_group_localization(c, group_id)
    locs = get_all(c, "v1/subscriptionGroups/#{group_id}/subscriptionGroupLocalizations",
                   "fields[subscriptionGroupLocalizations]" => "locale,name")
    if locs.any? { |l| l.dig("attributes", "locale") == "en-US" }
      puts "    ✓ group localization en-US present"
      return
    end
    body = {
      data: {
        type: "subscriptionGroupLocalizations",
        attributes: { name: GROUP_LOC_NAME, locale: "en-US" },
        relationships: {
          subscriptionGroup: { data: { type: "subscriptionGroups", id: group_id } }
        }
      }
    }
    c.post("v1/subscriptionGroupLocalizations", body)
    puts "    + added group localization en-US"
  end

  # ---------- Subscriptions ----------

  def find_or_create_subscription(c, group_id, spec)
    existing = get_all(c, "v1/subscriptionGroups/#{group_id}/subscriptions",
                       "fields[subscriptions]" => "productId,name,subscriptionPeriod,state")
    sub = existing.find { |s| s.dig("attributes", "productId") == spec[:product_id] }
    if sub
      puts "  ✓ subscription exists: #{sub['id']} (#{spec[:product_id]})"
      sub_id = sub["id"]
    else
      body = {
        data: {
          type: "subscriptions",
          attributes: {
            name: spec[:name],
            productId: spec[:product_id],
            familySharable: false,
            subscriptionPeriod: spec[:period],
            groupLevel: spec[:group_level],
            reviewNote: REVIEW_NOTE
          },
          relationships: {
            group: { data: { type: "subscriptionGroups", id: group_id } }
          }
        }
      }
      sub_id = c.post("v1/subscriptions", body).body.dig("data", "id")
      puts "  + created subscription: #{sub_id} (#{spec[:product_id]})"
    end

    ensure_subscription_localization(c, sub_id, spec)
    ensure_subscription_availability(c, sub_id)
    ensure_subscription_price(c, sub_id, spec[:price])
    ensure_subscription_intro(c, sub_id, spec[:intro]) if spec[:intro]
    ensure_review_screenshot(c, sub_id, kind: :subscription)
    sub_id
  end

  # Subscriptions must have territory availability set before prices can be assigned.
  # We enable availability in all current territories + opt-in to future ones.
  def ensure_subscription_availability(c, sub_id)
    avail = safe_get(c, "v1/subscriptions/#{sub_id}/subscriptionAvailability",
                     "fields[subscriptionAvailabilities]" => "availableInNewTerritories")
    if avail && avail["data"]
      puts "    ✓ subscription availability already set"
      return
    end
    territories = list_all_territory_ids(c)
    body = {
      data: {
        type: "subscriptionAvailabilities",
        attributes: { availableInNewTerritories: true },
        relationships: {
          subscription: { data: { type: "subscriptions", id: sub_id } },
          availableTerritories: {
            data: territories.map { |t| { type: "territories", id: t } }
          }
        }
      }
    }
    c.post("v1/subscriptionAvailabilities", body)
    puts "    + set availability in #{territories.size} territories (+ new)"
  end

  @@all_territory_ids = nil
  def list_all_territory_ids(c)
    @@all_territory_ids ||= get_all(c, "v1/territories",
                                    "fields[territories]" => "currency").map { |t| t["id"] }
  end

  def ensure_subscription_localization(c, sub_id, spec)
    locs = get_all(c, "v1/subscriptions/#{sub_id}/subscriptionLocalizations",
                   "fields[subscriptionLocalizations]" => "locale,name")
    if locs.any? { |l| l.dig("attributes", "locale") == "en-US" }
      puts "    ✓ subscription localization en-US present"
      return
    end
    body = {
      data: {
        type: "subscriptionLocalizations",
        attributes: { name: spec[:name], description: spec[:description], locale: "en-US" },
        relationships: {
          subscription: { data: { type: "subscriptions", id: sub_id } }
        }
      }
    }
    c.post("v1/subscriptionLocalizations", body)
    puts "    + added subscription localization en-US"
  end

  def find_subscription_price_point(c, sub_id, customer_price)
    pts = get_all(c, "v1/subscriptions/#{sub_id}/pricePoints",
                  "filter[territory]" => TERRITORY,
                  "fields[subscriptionPricePoints]" => "customerPrice,proceeds,territory")
    pt = pts.find { |p| p.dig("attributes", "customerPrice") == customer_price }
    raise "No subscription price point found for #{customer_price} USD on sub #{sub_id} (got #{pts.size} pts)" unless pt
    pt["id"]
  end

  def ensure_subscription_price(c, sub_id, customer_price)
    existing = get_all(c, "v1/subscriptions/#{sub_id}/prices",
                       "fields[subscriptionPrices]" => "startDate")
    if existing.any?
      puts "    ✓ subscription price already set (#{existing.size} entries)"
      return
    end
    pp_id = find_subscription_price_point(c, sub_id, customer_price)
    # Apple: first price entry must omit startDate (it goes live immediately).
    body = {
      data: {
        type: "subscriptionPrices",
        relationships: {
          subscription:           { data: { type: "subscriptions",            id: sub_id } },
          subscriptionPricePoint: { data: { type: "subscriptionPricePoints",  id: pp_id  } },
          territory:              { data: { type: "territories",              id: TERRITORY } }
        }
      }
    }
    c.post("v1/subscriptionPrices", body)
    puts "    + set subscription price to $#{customer_price} (USA, point #{pp_id})"
  end

  def ensure_subscription_intro(c, sub_id, intro)
    existing = get_all(c, "v1/subscriptions/#{sub_id}/introductoryOffers",
                       "fields[subscriptionIntroductoryOffers]" => "duration,offerMode,startDate,endDate")
    if existing.any?
      puts "    ✓ intro offer already configured (#{existing.size} entries)"
      return
    end

    attrs = {
      duration:        intro[:duration],
      offerMode:       intro[:mode],
      numberOfPeriods: 1,
      startDate:       nil,
      endDate:         nil
    }
    relationships = {
      subscription: { data: { type: "subscriptions", id: sub_id } },
      territory:    { data: { type: "territories",   id: TERRITORY } }
    }
    if intro[:mode] == "PAY_AS_YOU_GO"
      pp_id = find_subscription_price_point(c, sub_id, intro[:price])
      relationships[:subscriptionPricePoint] = { data: { type: "subscriptionPricePoints", id: pp_id } }
    end

    body = { data: { type: "subscriptionIntroductoryOffers", attributes: attrs, relationships: relationships } }
    c.post("v1/subscriptionIntroductoryOffers", body)
    puts "    + added #{intro[:mode]} intro offer (#{intro[:duration]})"
  end

  # ---------- Non-Consumable IAP (Lifetime) ----------

  def find_or_create_lifetime(c)
    spec = LIFETIME
    existing = get_all(c, "v1/apps/#{APP_ID}/inAppPurchasesV2",
                       "fields[inAppPurchases]" => "productId,name,inAppPurchaseType,state")
    iap = existing.find { |i| i.dig("attributes", "productId") == spec[:product_id] }
    if iap
      puts "  ✓ lifetime IAP exists: #{iap['id']} (#{spec[:product_id]})"
      iap_id = iap["id"]
    else
      body = {
        data: {
          type: "inAppPurchases",
          attributes: {
            name: spec[:name],
            productId: spec[:product_id],
            inAppPurchaseType: "NON_CONSUMABLE",
            reviewNote: REVIEW_NOTE,
            familySharable: false
          },
          relationships: { app: { data: { type: "apps", id: APP_ID } } }
        }
      }
      iap_id = c.post("v2/inAppPurchases", body).body.dig("data", "id")  # POST is v2; GET via v1
      puts "  + created lifetime IAP: #{iap_id}"
    end

    ensure_iap_localization(c, iap_id, spec)
    ensure_iap_price(c, iap_id, spec[:price])
    ensure_review_screenshot(c, iap_id, kind: :iap)
    iap_id
  end

  def ensure_iap_localization(c, iap_id, spec)
    locs = get_all(c, "v2/inAppPurchases/#{iap_id}/inAppPurchaseLocalizations",
                   "fields[inAppPurchaseLocalizations]" => "locale,name")
    if locs.any? { |l| l.dig("attributes", "locale") == "en-US" }
      puts "    ✓ IAP localization en-US present"
      return
    end
    body = {
      data: {
        type: "inAppPurchaseLocalizations",
        attributes: { name: spec[:name], description: spec[:description], locale: "en-US" },
        relationships: {
          inAppPurchaseV2: { data: { type: "inAppPurchases", id: iap_id } }
        }
      }
    }
    c.post("v1/inAppPurchaseLocalizations", body)
    puts "    + added IAP localization en-US"
  end

  def find_iap_price_point(c, iap_id, customer_price)
    pts = get_all(c, "v2/inAppPurchases/#{iap_id}/pricePoints",
                  "filter[territory]" => TERRITORY,
                  "fields[inAppPurchasePricePoints]" => "customerPrice,proceeds,territory")
    pt = pts.find { |p| p.dig("attributes", "customerPrice") == customer_price }
    raise "No IAP price point found for #{customer_price} USD on iap #{iap_id} (got #{pts.size} pts)" unless pt
    pt["id"]
  end

  def ensure_iap_price(c, iap_id, customer_price)
    sched = safe_get(c, "v2/inAppPurchases/#{iap_id}/iapPriceSchedule",
                     "fields[inAppPurchasePriceSchedules]" => "")
    if sched && sched["data"]
      puts "    ✓ IAP price schedule already set"
      return
    end
    pp_id = find_iap_price_point(c, iap_id, customer_price)
    body = {
      data: {
        type: "inAppPurchasePriceSchedules",
        relationships: {
          inAppPurchase: { data: { type: "inAppPurchases", id: iap_id } },
          baseTerritory: { data: { type: "territories",   id: TERRITORY } },
          manualPrices:  { data: [{ type: "inAppPurchasePrices", id: "${manualPrice}" }] }
        }
      },
      included: [
        {
          id: "${manualPrice}",
          type: "inAppPurchasePrices",
          attributes: { startDate: nil },
          relationships: {
            inAppPurchasePricePoint: { data: { type: "inAppPurchasePricePoints", id: pp_id } },
            territory:               { data: { type: "territories",              id: TERRITORY } },
            inAppPurchaseV2:         { data: { type: "inAppPurchases",           id: iap_id } }
          }
        }
      ]
    }
    c.post("v1/inAppPurchasePriceSchedules", body)
    puts "    + set IAP price to $#{customer_price} (USA, point #{pp_id})"
  end

  # ---------- App Review Screenshot (shared between subs + IAPs) ----------

  def ensure_review_screenshot(c, parent_id, kind:)
    file_path = REVIEW_SCREENSHOT_PATH
    unless File.exist?(file_path)
      puts "    ⚠ review screenshot missing at #{file_path}, skipping"
      return
    end

    rel_path, collection, type, rel_name, rel_type =
      case kind
      when :subscription
        ["v1/subscriptions/#{parent_id}/appStoreReviewScreenshot",
         "v1/subscriptionAppStoreReviewScreenshots",
         "subscriptionAppStoreReviewScreenshots",
         "subscription",
         "subscriptions"]
      when :iap
        ["v2/inAppPurchases/#{parent_id}/appStoreReviewScreenshot",
         "v1/inAppPurchaseAppStoreReviewScreenshots",
         "inAppPurchaseAppStoreReviewScreenshots",
         "inAppPurchaseV2",
         "inAppPurchases"]
      end

    existing = safe_get(c, rel_path)
    if existing && existing["data"]
      puts "    ✓ review screenshot already uploaded"
      return
    end

    bytes = File.binread(file_path)
    reserve_body = {
      data: {
        type: type,
        attributes: { fileName: File.basename(file_path), fileSize: bytes.bytesize },
        relationships: { rel_name => { data: { type: rel_type, id: parent_id } } }
      }
    }
    reserve = c.post(collection, reserve_body).body
    ss_id = reserve.dig("data", "id")
    ops   = reserve.dig("data", "attributes", "uploadOperations")
    Spaceship::ConnectAPI::FileUploader.upload(ops, bytes)
    c.patch("#{collection}/#{ss_id}", {
      data: {
        type: type,
        id: ss_id,
        attributes: {
          uploaded: true,
          sourceFileChecksum: Digest::MD5.hexdigest(bytes)
        }
      }
    })
    puts "    + uploaded review screenshot (#{File.basename(file_path)}, #{bytes.bytesize} bytes)"
  end

  # ---------- Age Rating ----------

  def set_age_rating!(c)
    info = c.get("v1/apps/#{APP_ID}/appInfos",
                 "include" => "ageRatingDeclaration").body
    rel = info.dig("data", 0, "relationships", "ageRatingDeclaration", "data")
    raise "No ageRatingDeclaration relationship found on app info" unless rel
    decl_id = rel["id"]

    # All-NONE / all-false attributes for a 4+ rating: no objectionable content.
    attrs = {
      alcoholTobaccoOrDrugUseOrReferences: "NONE",
      contests: "NONE",
      gamblingSimulated: "NONE",
      gunsOrOtherWeapons: "NONE",
      horrorOrFearThemes: "NONE",
      matureOrSuggestiveThemes: "NONE",
      medicalOrTreatmentInformation: "NONE",
      profanityOrCrudeHumor: "NONE",
      sexualContentGraphicAndNudity: "NONE",
      sexualContentOrNudity: "NONE",
      violenceCartoonOrFantasy: "NONE",
      violenceRealistic: "NONE",
      violenceRealisticProlongedGraphicOrSadistic: "NONE",
      gambling: false,
      unrestrictedWebAccess: false,
      userGeneratedContent: false,
      messagingAndChat: false,
      lootBox: false,
      advertising: false,
      ageAssurance: false,
      healthOrWellnessTopics: false,
      parentalControls: false,
      ageRatingOverrideV2: "NONE",
      koreaAgeRatingOverride: "NONE"
    }
    body = { data: { type: "ageRatingDeclarations", id: decl_id, attributes: attrs } }
    c.patch("v1/ageRatingDeclarations/#{decl_id}", body)
    puts "  ✓ age rating set to 4+ (all categories NONE/false) — declaration #{decl_id}"
  end

  # ---------- Driver ----------

  def run!
    puts "ASC IAP provisioning for app #{APP_ID}"
    c = client

    puts "[1/4] Subscription group..."
    group_id = find_or_create_group(c)

    puts "[2/4] Subscriptions..."
    SUBSCRIPTIONS.each { |spec| find_or_create_subscription(c, group_id, spec) }

    puts "[3/4] Lifetime non-consumable..."
    find_or_create_lifetime(c)

    puts "[4/4] Age rating..."
    set_age_rating!(c)

    puts ""
    puts "Done. Re-run safely; this script is idempotent."
    puts ""
    puts "NOTE: App Privacy nutrition labels are not exposed by the public ASC"
    puts "REST API (only via the iris/cookie-auth backend). Set in the dashboard:"
    puts "  https://appstoreconnect.apple.com/apps/#{APP_ID}/distribution/privacy"
    puts "  → 'Data Not Collected' (Prune has no analytics SDK or third-party"
    puts "    purchase tracker after dropping RevenueCat)."
  end
end

ASCIaps.run! if __FILE__ == $0
