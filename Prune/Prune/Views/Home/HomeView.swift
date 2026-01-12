import SwiftUI
import Photos

struct HomeView: View {
    @StateObject var photoService = PhotoLibraryService.shared
    @StateObject var purchaseService = PurchaseService.shared
    
    @State private var path = NavigationPath()
    @State private var showPaywall = false
    @State private var showDateSelector = false
    
    // Feeds definition
    var feeds: [Feed] {
        [
            Feed(type: .recents, title: "All Photos", subtitle: "Clean up everything", iconName: "photo.stack", isProLocked: false, color: .blue),
            Feed(type: .timeframe("Today"), title: "Today", subtitle: "Quick check", iconName: "calendar", isProLocked: true, color: .purple),
            Feed(type: .dateRange(Date(), Date()), title: "Date Range", subtitle: "Travel back in time", iconName: "calendar.badge.clock", isProLocked: true, color: .indigo),
            Feed(type: .selfies, title: "Selfies", subtitle: "Quick clean", iconName: "person.crop.circle", isProLocked: true, color: .pink),
            Feed(type: .screenshots, title: "Screenshots", subtitle: "Clutter", iconName: "camera.viewfinder", isProLocked: true, color: .cyan),
            Feed(type: .videos, title: "Videos", subtitle: "Large files", iconName: "play.rectangle.fill", isProLocked: true, color: .red),
            Feed(type: .favorites, title: "Favorites", subtitle: "Only the best", iconName: "heart.fill", isProLocked: true, color: .yellow)
        ]
    }
    
    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                // Clean Black Background
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Header
                        HStack {
                            Text("Prune")
                                .font(.system(size: 40, weight: .bold))
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            if !purchaseService.isPro {
                                Button(action: { showPaywall = true }) {
                                    Text("PRO")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 4)
                                        .background(
                                            Capsule()
                                                .stroke(Color.white, lineWidth: 1)
                                        )
                                        .foregroundColor(.white)
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 20)
                        
                        // Featured Card (First Item)
                        if let first = feeds.first {
                            FeaturedFeedCard(feed: first, isPro: purchaseService.isPro) {
                                if first.isProLocked && !purchaseService.isPro {
                                    showPaywall = true
                                } else {
                                    path.append(first.type)
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        Text("Categories")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal)
                        
                        // Grid for the rest
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(feeds.dropFirst()) { feed in
                                GridFeedCard(feed: feed, isPro: purchaseService.isPro) {
                                    if feed.isProLocked && !purchaseService.isPro {
                                        showPaywall = true
                                    } else {
                                        // Specific check for Date Range placeholder
                                        if case .dateRange = feed.type {
                                            showDateSelector = true
                                        } else {
                                            path.append(feed.type)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationDestination(for: FeedType.self) { feedType in
                SwipeDeckView(feedType: feedType)
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
            .sheet(isPresented: $showDateSelector) {
                DateSelectionView { start, end in
                    // Need to check Pro status before navigating?
                    // Let's assume date selection is Pro.
                    if !purchaseService.isPro {
                        showPaywall = true // Re-open paywall if locked
                    } else {
                        path.append(FeedType.dateRange(start, end))
                    }
                }
                .presentationDetents([.medium, .large])
            }
            .task {
                if photoService.permissionStatus == .notDetermined {
                   _ = await photoService.requestAuthorization()
                }
            }
        }
    }
}

struct FeaturedFeedCard: View {
    let feed: Feed
    let isPro: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(feed.color.opacity(0.15))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: feed.iconName)
                        .font(.title2)
                        .foregroundColor(feed.color)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(feed.title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    if let sub = feed.subtitle {
                        Text(sub)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.body)
                    .foregroundColor(.gray)
            }
            .padding(24)
            .background(Color(white: 0.1))
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
    }
}

struct GridFeedCard: View {
    let feed: Feed
    let isPro: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: feed.iconName)
                        .font(.title3)
                        .foregroundColor(feed.color)
                        .padding(10)
                        .background(feed.color.opacity(0.2))
                        .clipShape(Circle())
                    
                    Spacer()
                    
                    if feed.isProLocked && !isPro {
                        Image(systemName: "lock.fill")
                            .font(.caption2)
                            .foregroundColor(.gray)
                            .padding(6)
                            .background(Color.black.opacity(0.3))
                            .clipShape(Circle())
                    }
                }
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(feed.title)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    if let sub = feed.subtitle {
                        Text(sub)
                            .font(.caption)
                            .foregroundColor(.gray)
                            .lineLimit(1)
                    }
                }
            }
            .padding(16)
            .frame(height: 130)
             .background(Color(white: 0.1))
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
    }
}
