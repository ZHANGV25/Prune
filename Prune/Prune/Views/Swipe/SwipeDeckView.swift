import SwiftUI
import Photos
import AVKit

struct SwipeDeckView: View {
    @Environment(\.dismiss) var dismissAction
    @StateObject private var viewModel: SwipeViewModel
    
    // UI State for Gesture
    @State private var translation: CGSize = .zero
    @State private var showFinishScreen = false
    @State private var showUndoFeedback = false
    @State private var showFavoriteFeedback = false
    @State private var showInfoSheet = false
    @State private var showPaywall = false
    
    init(feedType: FeedType) {
        _viewModel = StateObject(wrappedValue: SwipeViewModel(feedType: feedType))
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if showFinishScreen {
                FinishView(
                    pendingAssets: viewModel.photoAssets.filter { viewModel.pendingDeletes.contains($0.localIdentifier) },
                    onCommit: commitDeletes,
                    onDiscard: { dismiss() },
                    onRestore: { asset in
                        viewModel.pendingDeletes.remove(asset.localIdentifier)
                    }
                )
            } else if viewModel.isLoading {
                VStack(spacing: 20) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                    Text("Loading Photos...")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.8))
                }
            } else if viewModel.items.isEmpty {
                 VStack(spacing: 24) {
                     Image(systemName: "photo.on.rectangle.angled")
                         .font(.system(size: 60))
                         .foregroundColor(.gray)
                     
                     VStack(spacing: 8) {
                         Text("No Photos Found")
                             .font(.title2)
                             .bold()
                             .foregroundColor(.white)
                         
                         Text("Try selecting a different category.")
                             .font(.body)
                             .foregroundColor(.gray)
                     }
                     
                     Button(action: { dismiss() }) {
                         Text("Go Back")
                             .font(.headline)
                             .foregroundColor(.black)
                             .padding(.horizontal, 32)
                             .padding(.vertical, 16)
                             .background(Color.white)
                             .cornerRadius(25)
                     }
                 }
            } else if viewModel.isFinished {
                // Finished State
                FinishView(
                    pendingAssets: viewModel.photoAssets.filter { viewModel.pendingDeletes.contains($0.localIdentifier) },
                    onCommit: commitDeletes,
                    onDiscard: { dismiss() },
                    onRestore: { asset in
                        viewModel.pendingDeletes.remove(asset.localIdentifier)
                    }
                )
            } else {
                // The Card Stack
                ZStack {
                    if let current = viewModel.currentItem {
                        
                        GeometryReader { geometry in
                            Group {
                                switch current {
                                case .photo(let asset):
                                    PhotoCard(
                                        asset: asset,
                                        cachedImage: viewModel.imageCache[asset.localIdentifier],
                                        preloadedVideo: viewModel.videoItemCache[asset.localIdentifier]
                                    )
                                    .id(asset.localIdentifier) // Important for transition identity
                                    .overlay(alignment: .bottomLeading) {
                                        if translation.width > 50 {
                                            Text("KEEP")
                                                .font(.largeTitle)
                                                .fontWeight(.heavy)
                                                .foregroundColor(.green)
                                                .padding()
                                                .background(
                                                    RoundedRectangle(cornerRadius: 10)
                                                        .stroke(Color.green, lineWidth: 4)
                                                )
                                                .rotationEffect(.degrees(-15))
                                                .padding(.bottom, 150)
                                                .padding(.leading, 40)
                                                .opacity(Double(translation.width / 150))
                                        }
                                    }
                                    .overlay(alignment: .bottomTrailing) {
                                        if translation.width < -50 {
                                            Text("DELETE")
                                                .font(.largeTitle)
                                                .fontWeight(.heavy)
                                                .foregroundColor(.red)
                                                .padding()
                                                .background(
                                                    RoundedRectangle(cornerRadius: 10)
                                                        .stroke(Color.red, lineWidth: 4)
                                                )
                                                .rotationEffect(.degrees(15))
                                                .padding(.bottom, 150)
                                                .padding(.trailing, 40)
                                                .opacity(Double(-translation.width / 150))
                                        }
                                    }
                                    .overlay(alignment: .center) {
                                        if showFavoriteFeedback {
                                            Image(systemName: "heart.fill")
                                                .font(.system(size: 100))
                                                .foregroundColor(.red)
                                                .shadow(radius: 10)
                                                .opacity(0.8)
                                                .transition(.scale.combined(with: .opacity))
                                        }
                                    }
                                    
                                case .ad(let id, let nativeAd):
                                    AdCard(nativeAd: nativeAd) {
                                        // On Click Button
                                        withAnimation(.spring()) {
                                            viewModel.swipedRight() // Treat as keep/dismiss
                                            translation = .zero
                                        }
                                        showPaywall = true
                                    }
                                    .id(id)
                                }
                            }
                            .offset(x: translation.width, y: translation.height)
                            .rotationEffect(.degrees(Double(translation.width / 20)))
                            // Transition Logic
                            .transition(
                                viewModel.isUndoing
                                ? .asymmetric(
                                    insertion: .move(edge: viewModel.lastUndoDirection == .left ? .leading : .trailing),
                                    removal: .identity
                                  )
                                : .asymmetric(
                                    insertion: .scale(scale: 0.1).combined(with: .opacity),
                                    removal: .identity
                                  )
                            )
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        translation = value.translation
                                    }
                                    .onEnded { value in
                                        handleSwipe(translation: value.translation)
                                    }
                            )
                            // Clean Tap Gesture
                            .onTapGesture {
                                // Only undo if it's a photo, or general undo?
                                // Let's allow global undo.
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                    viewModel.undo()
                                }
                            }
                        }
                    }
                }
                
                // Floating Controls Overlay
                VStack {
                    // Header
                    HStack {
                         Button(action: {
                             if !viewModel.pendingDeletes.isEmpty {
                                 showFinishScreen = true
                             } else {
                                 dismiss()
                             }
                         }) {
                             Image(systemName: "chevron.left.circle.fill")
                                 .font(.system(size: 40))
                                 .foregroundColor(.white)
                                 .shadow(radius: 4)
                                 .padding(8)
                         }

                        Spacer()
                        
                        if !viewModel.items.isEmpty {
                            Text("\(viewModel.items.count - viewModel.currentIndex) left")
                                .font(.headline)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(.ultraThinMaterial)
                                .cornerRadius(20)
                                .foregroundColor(.white)
                        }

                        Spacer()
                        
                        // Info Button
                        Button(action: {
                            showInfoSheet = true
                        }) {
                             Image(systemName: "info.circle.fill")
                                 .font(.system(size: 30))
                                 .foregroundColor(.white.opacity(0.8))
                                 .shadow(radius: 4)
                                 .padding(8)
                        }
                    }
                    .padding()
                    
                    Spacer()
                    
                    // Footer Indicators
                    HStack(spacing: 40) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.left")
                            Text("DELETE")
                        }
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.red.opacity(0.8))
                        
                        Text("|")
                            .foregroundColor(.white.opacity(0.3))
                        
                        HStack(spacing: 4) {
                            Text("KEEP")
                            Image(systemName: "arrow.right")
                        }
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.green.opacity(0.8))
                    }
                    .padding(.bottom, 30)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .sheet(isPresented: $showInfoSheet) {
            if let asset = viewModel.currentAsset {
                AssetInfoView(asset: asset)
                    .presentationDetents([.medium, .fraction(0.3)])
            } else {
                Text("No Info Available")
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
        .task {
            await viewModel.loadAssets()
        }
    }
    
    func handleSwipe(translation: CGSize) {
        let threshold: CGFloat = 100
        
        if translation.width > threshold {
            // KEEP
            
            // CHECK IF AD
            if let current = viewModel.currentItem {
                if case .ad = current {
                    showPaywall = true
                }
            }
            
            withAnimation(.easeOut(duration: 0.2)) {
                self.translation = .init(width: 1000, height: 0)
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    viewModel.swipedRight()
                }
                self.translation = .zero
            }
        } else if translation.width < -threshold {
            // DELETE
            withAnimation(.easeOut(duration: 0.2)) {
                self.translation = .init(width: -1000, height: 0)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    viewModel.swipedLeft()
                }
                self.translation = .zero
            }
        } else {
            // Reset (Snap Back)
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                self.translation = .zero
            }
        }
    }
    
    func commitDeletes() {
        Task {
            await viewModel.commitDeletes()
            dismiss()
        }
    }
    
    func dismiss() {
        dismissAction()
    }
}

struct PhotoCard: View {
    let asset: PHAsset
    let cachedImage: UIImage?
    let preloadedVideo: AVPlayerItem?
    
    @State private var image: UIImage?
    @State private var player: AVPlayer?
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                if asset.mediaType == .video {
                    if let player = player {
                        VideoPlayer(player: player)
                            .frame(width: geo.size.width, height: geo.size.height)
                            .clipped()
                            .cornerRadius(20)
                            .onAppear {
                                player.play()
                                NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: player.currentItem, queue: .main) { _ in
                                    player.seek(to: .zero)
                                    player.play()
                                }
                            }
                            .onDisappear {
                                player.pause()
                            }
                    } else {
                        // Placeholder
                        if let img = cachedImage ?? image {
                            Image(uiImage: img)
                                .resizable()
                                .scaledToFill()
                                .frame(width: geo.size.width, height: geo.size.height)
                                .clipped()
                                .cornerRadius(20)
                                .overlay(
                                    Image(systemName: "play.circle.fill")
                                        .font(.system(size: 60))
                                        .foregroundColor(.white.opacity(0.8))
                                )
                        } else {
                            ProgressView()
                                .frame(width: geo.size.width, height: geo.size.height)
                        }
                    }
                } else {
                    // Photo
                    if let img = cachedImage ?? image {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFill()
                            .frame(width: geo.size.width, height: geo.size.height)
                            .clipped()
                            .cornerRadius(20)
                    } else {
                        ZStack {
                            Color.gray.opacity(0.3)
                            ProgressView()
                        }
                        .frame(width: geo.size.width, height: geo.size.height)
                        .cornerRadius(20)
                    }
                }
            }
        }
        .padding(12)
        .shadow(radius: 10)
        .onAppear {
            if cachedImage == nil {
                fetchImage()
            }
            if asset.mediaType == .video {
                loadVideo()
            }
        }
        .onChange(of: cachedImage) { newImage in
            if let newImage = newImage {
                self.image = newImage
            }
        }
    }
    
    func fetchImage() {
        let manager = PHCachingImageManager.default()
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        options.isSynchronous = false
        
        manager.requestImage(for: asset, targetSize: CGSize(width: 600, height: 800), contentMode: .aspectFill, options: options) { res, _ in
            self.image = res
        }
    }
    
    func loadVideo() {
        if let preloaded = preloadedVideo {
            self.player = AVPlayer(playerItem: preloaded)
            self.player?.isMuted = true
            return
        }
        
        let manager = PHCachingImageManager.default()
        let options = PHVideoRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .highQualityFormat
        
        manager.requestPlayerItem(forVideo: asset, options: options) { item, _ in
            if let item = item {
                DispatchQueue.main.async {
                    self.player = AVPlayer(playerItem: item)
                    self.player?.isMuted = true
                }
            }
        }
    }
}

struct FinishView: View {
    let pendingAssets: [PHAsset]
    let onCommit: () -> Void
    let onDiscard: () -> Void
    let onRestore: (PHAsset) -> Void
    
    @State private var selectedAsset: PHAsset?
    
    let columns = [
        GridItem(.adaptive(minimum: 100), spacing: 2)
    ]
    
    var body: some View {
        ZStack {
            VStack(spacing: 20) {
                Text("For Your Approval")
                    .font(.title)
                    .bold()
                    .foregroundColor(.white)
                    .padding(.top, 40)
                
                if pendingAssets.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.green)
                        Text("No Photos to Delete!")
                            .font(.title2)
                            .bold()
                            .foregroundColor(.white)
                        Text("You kept everything. Good job!")
                            .foregroundColor(.gray)
                    }
                    Spacer()
                } else {
                    Text("You selected \(pendingAssets.count) photos to delete.")
                        .font(.body)
                        .foregroundColor(.gray)
                    
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 2) {
                            ForEach(pendingAssets, id: \.localIdentifier) { asset in
                                PhotoThumbnail(asset: asset)
                                    .aspectRatio(1, contentMode: .fill)
                                    .clipped()
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        selectedAsset = asset
                                    }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .background(Color(white: 0.1))
                    .cornerRadius(12)
                    .padding()
                }
                
                VStack(spacing: 16) {
                    if !pendingAssets.isEmpty {
                        Button(action: onCommit) {
                            Text("Delete \(pendingAssets.count) Photos")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red)
                                .cornerRadius(12)
                        }
                    }
                    
                    Button(action: onDiscard) {
                        Text("Exit (Discard Changes)")
                        .font(.headline)
                        .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
            .blur(radius: selectedAsset != nil ? 20 : 0)
            
            // Full Screen Preview
            if let asset = selectedAsset {
                Color.black.opacity(0.9).ignoresSafeArea()
                    .onTapGesture { selectedAsset = nil }
                
                VStack {
                    HStack {
                        Spacer()
                        Button(action: { selectedAsset = nil }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 30))
                                .foregroundColor(.white)
                                .padding()
                        }
                    }
                    
                    Spacer()
                    
                    PhotoCard(asset: asset, cachedImage: nil, preloadedVideo: nil)
                        .aspectRatio(contentMode: .fit)
                        .padding()
                    
                    Spacer()
                    
                    Button(action: {
                        onRestore(asset)
                        selectedAsset = nil
                    }) {
                        Label("Keep This Photo", systemImage: "arrow.uturn.backward")
                            .font(.headline)
                            .foregroundColor(.black)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.white)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 40)
                }
                .transition(.scale.combined(with: .opacity))
                .zIndex(100)
            }
        }
        .background(Color.black)
    }
}

struct PhotoThumbnail: View {
    let asset: PHAsset
    @State private var image: UIImage?
    
    var body: some View {
        GeometryReader { geo in
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
                
            } else {
                Color.gray
            }
        }
        .task {
            let manager = PHCachingImageManager.default()
            let options = PHImageRequestOptions()
            options.deliveryMode = .fastFormat
            options.isSynchronous = false
            
            manager.requestImage(for: asset, targetSize: CGSize(width: 200, height: 200), contentMode: .aspectFill, options: options) { res, _ in
                self.image = res
            }
        }
    }
}
