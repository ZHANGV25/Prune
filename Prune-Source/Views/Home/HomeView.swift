import SwiftUI

struct HomeView: View {
    @StateObject var photoService = PhotoLibraryService.shared
    @StateObject var purchaseService = PurchaseService.shared
    
    @State private var selectedFeed: FeedType?
    @State private var showPaywall = false
    
    // Feeds definition
    var feeds: [Feed] {
        [
            Feed(type: .recents, title: "Recents", subtitle: "All photos sorted by date", iconName: "clock", isProLocked: false),
            Feed(type: .timeframe("Today"), title: "Today", subtitle: nil, iconName: "calendar", isProLocked: true),
            Feed(type: .timeframe("Last 7 Days"), title: "Last 7 Days", subtitle: nil, iconName: "calendar.badge.clock", isProLocked: true),
            Feed(type: .location("Cities"), title: "Locations", subtitle: "Grouped by city", iconName: "map", isProLocked: true)
        ]
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemBackground).ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Prune")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .padding(.horizontal)
                            .padding(.top, 20)
                        
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 16)], spacing: 16) {
                            ForEach(feeds) { feed in
                                FeedCard(feed: feed, isPro: purchaseService.isPro) {
                                    if feed.isProLocked && !purchaseService.isPro {
                                        showPaywall = true
                                    } else {
                                        selectedFeed = feed.type
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .navigationDestination(item: $selectedFeed) { feedType in
                SwipeDeckView(feedType: feedType)
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
            .task {
                if photoService.permissionStatus == .notDetermined {
                   _ = await photoService.requestAuthorization()
                }
            }
        }
    }
}

struct FeedCard: View {
    let feed: Feed
    let isPro: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: feed.iconName)
                        .font(.title2)
                        .foregroundColor(.primary)
                    Spacer()
                    if feed.isProLocked && !isPro {
                        Image(systemName: "lock.fill")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(feed.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    if let sub = feed.subtitle {
                        Text(sub)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .frame(height: 120)
            .background(.regularMaterial)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
    }
}
