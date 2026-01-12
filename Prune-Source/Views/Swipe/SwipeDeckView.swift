import SwiftUI
import Photos

struct SwipeDeckView: View {
    @Environment(\.dismiss) var dismissAction
    @StateObject private var viewModel: SwipeViewModel
    
    // UI State for Gesture
    @State private var translation: CGSize = .zero
    @State private var showFinishScreen = false
    
    init(feedType: FeedType) {
        _viewModel = StateObject(wrappedValue: SwipeViewModel(feedType: feedType))
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if showFinishScreen {
                FinishView(
                    pendingCount: viewModel.pendingDeletes.count,
                    onCommit: commitDeletes,
                    onDiscard: { dismiss() }
                )
            } else if viewModel.assets.isEmpty {
                 // Check if actually empty or just loading? 
                 // VM loads synchronously for MVP fetch, but ideally it should be async.
                 // We will assume if empty after load, it's empty.
                 // We can add a simple check in VM for "isLoading".
                 // For now, if 0 assets, just show "No photos found".
                Text("No photos found in this feed.")
                    .foregroundColor(.white)
            } else if viewModel.isFinished {
                // End of stack
                VStack(spacing: 20) {
                    Text("All Caught Up!")
                        .font(.largeTitle)
                        .foregroundColor(.white)
                    Button("Review Deletions (\(viewModel.pendingDeletes.count))") {
                        showFinishScreen = true
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else {
                // The Stack
                ZStack {
                    if let next = viewModel.nextAsset {
                        PhotoCard(asset: next)
                            .scaleEffect(0.95)
                            .opacity(0.6)
                    }
                    
                    if let current = viewModel.currentAsset {
                        PhotoCard(asset: current)
                            .offset(x: translation.width, y: translation.height)
                            .rotationEffect(.degrees(Double(translation.width / 20)))
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        translation = value.translation
                                    }
                                    .onEnded { value in
                                        handleSwipe(translation: value.translation)
                                    }
                            )
                            .overlay(alignment: .topLeading) {
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
                                        .padding(40)
                                        .opacity(Double(translation.width / 150))
                                }
                            }
                            .overlay(alignment: .topTrailing) {
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
                                        .padding(40)
                                        .opacity(Double(-translation.width / 150))
                                }
                            }
                    }
                }
                
                // HUD
                VStack {
                    HStack {
                        Button(action: {
                            withAnimation { viewModel.undo() }
                        }) {
                            Image(systemName: "arrow.uturn.backward.circle.fill")
                                .font(.system(size: 44))
                                .foregroundColor(.white)
                        }
                        .disabled(viewModel.currentIndex == 0)
                        
                        Spacer()
                        
                        Text("\(viewModel.assets.count - viewModel.currentIndex) left")
                            .font(.headline)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(.ultraThinMaterial)
                            .cornerRadius(20)
                            .foregroundColor(.white)
                    }
                    .padding()
                    Spacer()
                }
            }
        }
        .task {
            viewModel.loadAssets()
        }
    }
    
    func handleSwipe(translation: CGSize) {
        let threshold: CGFloat = 100
        
        if translation.width > threshold {
            // KEEP
            withAnimation(.spring()) {
                self.translation = .init(width: 1000, height: 0)
            }
            // Delay update to allow animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                viewModel.swipedRight()
                self.translation = .zero
            }
        } else if translation.width < -threshold {
            // DELETE
            withAnimation(.spring()) {
                self.translation = .init(width: -1000, height: 0)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                viewModel.swipedLeft()
                self.translation = .zero
            }
        } else {
            // Reset
            withAnimation(.spring()) {
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
