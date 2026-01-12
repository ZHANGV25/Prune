import SwiftUI
import GoogleMobileAds
import UIKit

struct AdCard: View {
    let nativeAd: NativeAd?
    let onDismiss: () -> Void
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                if let ad = nativeAd {
                    // Google Native Ad
                    NativeAdViewWrapper(nativeAd: ad)
                        .cornerRadius(20)
                        .shadow(radius: 10)
                } else {
                    // Fallback House Ad
                    HouseAdView(onDismiss: onDismiss)
                }
            }
        }
        .padding(12)
    }
}

// MARK: - House Ad (Prune Pro)
struct HouseAdView: View {
    let onDismiss: () -> Void
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            VStack(spacing: 24) {
                Image(systemName: "star.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.yellow)
                    .shadow(radius: 10)
                
                VStack(spacing: 8) {
                    Text("Enjoying Prune?")
                        .font(.largeTitle)
                        .fontWeight(.heavy)
                        .foregroundColor(.white)
            Color(UIColor.secondarySystemBackground)
            VStack {
                 Text("Prune Pro")
                    .font(.largeTitle)
                    .bold()
                 Text("Support development & Remove Ads")
                 Button("Upgrade") {
                     onDismiss()
                 }
                 .buttonStyle(.borderedProminent)
            }
        }
    }
}

// MARK: - Native Ad Wrapper
struct NativeAdViewWrapper: UIViewRepresentable {
    let nativeAd: NativeAd
    
    func makeUIView(context: Context) -> NativeAdView {
        return constructNativeAdView()
    }
    
    func updateUIView(_ uiView: NativeAdView, context: Context) {
        uiView.nativeAd = nativeAd
        (uiView.headlineView as? UILabel)?.text = nativeAd.headline
        (uiView.bodyView as? UILabel)?.text = nativeAd.body
        (uiView.callToActionView as? UIButton)?.setTitle(nativeAd.callToAction, for: .normal)
        (uiView.iconView as? UIImageView)?.image = nativeAd.icon?.image
        
        // Media View
        if let mediaView = uiView.mediaView {
            mediaView.mediaContent = nativeAd.mediaContent
        }
    }
    
    func constructNativeAdView() -> NativeAdView {
        let adView = NativeAdView()
        adView.backgroundColor = .secondarySystemBackground
        adView.clipsToBounds = true // Ensure content doesn't bleed out visually, though frames must still be valid
        
        // Create Views
        let iconView = UIImageView()
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.contentMode = .scaleAspectFit
        iconView.layer.cornerRadius = 10
        iconView.clipsToBounds = true
        adView.addSubview(iconView)
        adView.iconView = iconView
        
        let headlineLabel = UILabel()
        headlineLabel.translatesAutoresizingMaskIntoConstraints = false
        headlineLabel.font = .boldSystemFont(ofSize: 17)
        headlineLabel.textColor = .label
        headlineLabel.numberOfLines = 2
        adView.addSubview(headlineLabel)
        adView.headlineView = headlineLabel
        
        let bodyLabel = UILabel()
        bodyLabel.translatesAutoresizingMaskIntoConstraints = false
        bodyLabel.font = .systemFont(ofSize: 14)
        bodyLabel.textColor = .secondaryLabel
        bodyLabel.numberOfLines = 3
        adView.addSubview(bodyLabel)
        adView.bodyView = bodyLabel
        
        let mediaView = MediaView()
        mediaView.translatesAutoresizingMaskIntoConstraints = false
        mediaView.contentMode = .scaleAspectFill
        mediaView.clipsToBounds = true
        adView.addSubview(mediaView)
        adView.mediaView = mediaView
        
        let ctaButton = UIButton(type: .system)
        ctaButton.translatesAutoresizingMaskIntoConstraints = false
        ctaButton.setTitle("Details", for: .normal)
        ctaButton.backgroundColor = .systemBlue
        ctaButton.setTitleColor(.white, for: .normal)
        ctaButton.layer.cornerRadius = 10
        ctaButton.isUserInteractionEnabled = false // Let NativeAdView handle clicks
        adView.addSubview(ctaButton)
        adView.callToActionView = ctaButton
        
        let adBadge = UILabel()
        adBadge.translatesAutoresizingMaskIntoConstraints = false
        adBadge.text = "Ad"
        adBadge.font = .systemFont(ofSize: 11, weight: .bold)
        adBadge.textColor = .white
        adBadge.backgroundColor = .orange
        adBadge.layer.cornerRadius = 3
        adBadge.clipsToBounds = true
        adBadge.textAlignment = .center
        adView.addSubview(adBadge)
        
        // Constraints
        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: adView.leadingAnchor, constant: 15),
            iconView.topAnchor.constraint(equalTo: adView.topAnchor, constant: 15),
            iconView.widthAnchor.constraint(equalToConstant: 50),
            iconView.heightAnchor.constraint(equalToConstant: 50),
            
            headlineLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 10),
            headlineLabel.topAnchor.constraint(equalTo: iconView.topAnchor),
            headlineLabel.trailingAnchor.constraint(equalTo: adView.trailingAnchor, constant: -15),
            
            adBadge.leadingAnchor.constraint(equalTo: locationSafe(iconView.leadingAnchor)), // Just safe placement
            adBadge.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 5),
            adBadge.widthAnchor.constraint(equalToConstant: 25),
            adBadge.heightAnchor.constraint(equalToConstant: 16),

            bodyLabel.leadingAnchor.constraint(equalTo: iconView.leadingAnchor),
            bodyLabel.topAnchor.constraint(equalTo: adBadge.bottomAnchor, constant: 10),
            bodyLabel.trailingAnchor.constraint(equalTo: adView.trailingAnchor, constant: -15),
            
            mediaView.leadingAnchor.constraint(equalTo: adView.leadingAnchor),
            mediaView.trailingAnchor.constraint(equalTo: adView.trailingAnchor),
            mediaView.topAnchor.constraint(equalTo: bodyLabel.bottomAnchor, constant: 15),
            mediaView.heightAnchor.constraint(equalToConstant: 250), // Fixed height for media
            
            ctaButton.leadingAnchor.constraint(equalTo: adView.leadingAnchor, constant: 15),
            ctaButton.trailingAnchor.constraint(equalTo: adView.trailingAnchor, constant: -15),
            ctaButton.topAnchor.constraint(equalTo: mediaView.bottomAnchor, constant: 20),
            ctaButton.heightAnchor.constraint(equalToConstant: 50),
            
            // IMPORTANT: Constrain bottom so content doesn't overflow or if view resizes, content is respected
             ctaButton.bottomAnchor.constraint(lessThanOrEqualTo: adView.bottomAnchor, constant: -20)
        ])
        
        // Helper
        func locationSafe(_ anchor: NSLayoutXAxisAnchor) -> NSLayoutXAxisAnchor { return anchor }
        
        return adView
    }
}
