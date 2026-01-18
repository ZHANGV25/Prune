import SwiftUI
import GoogleMobileAds
import UIKit

// MARK: - AdCard
struct AdCard: View {
    let nativeAd: NativeAd?
    let onDismiss: () -> Void
    
    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                if let ad = nativeAd {
                    // Remove Ads button
                    HStack {
                        Spacer()
                        Button(action: onDismiss) {
                            HStack(spacing: 4) {
                                Image(systemName: "crown.fill")
                                Text("Remove Ads")
                                    .font(.caption)
                                    .fontWeight(.bold)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(.ultraThinMaterial)
                            .cornerRadius(16)
                            .foregroundColor(.primary)
                        }
                    }
                    .padding(.bottom, 8)
                    
                    // Native Ad View
                    NativeAdContainerView(nativeAd: ad)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                } else {
                    HouseAdView(onDismiss: onDismiss)
                        .cornerRadius(20)
                }
            }
        }
        .padding(EdgeInsets(top: 70, leading: 12, bottom: 100, trailing: 12))
    }
}

// MARK: - House Ad
struct HouseAdView: View {
    let onDismiss: () -> Void
    var body: some View {
        ZStack {
            Color(UIColor.secondarySystemBackground)
            VStack(spacing: 16) {
                Text("Pruned Pro").font(.largeTitle).bold()
                Text("Support development & Remove Ads").foregroundColor(.secondary)
                Button("Upgrade") { onDismiss() }.buttonStyle(.borderedProminent)
            }
        }
    }
}

// MARK: - Native Ad Container
struct NativeAdContainerView: UIViewRepresentable {
    let nativeAd: NativeAd
    
    func makeUIView(context: Context) -> PruneNativeAdView {
        return PruneNativeAdView()
    }
    
    func updateUIView(_ uiView: PruneNativeAdView, context: Context) {
        DispatchQueue.main.async {
            uiView.configure(with: nativeAd)
        }
    }
}

// MARK: - Custom NativeAdView
class PruneNativeAdView: NativeAdView {
    
    private var isConfigured = false
    
    private let iconImageView = UIImageView()
    private let headlineLabel = UILabel()
    private let bodyLabel = UILabel()
    private let ctaButton = UIButton(type: .system)
    private let adMediaView = MediaView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = UIColor.secondarySystemBackground
        clipsToBounds = true
        layer.masksToBounds = true
        
        let margin: CGFloat = 16
        
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.contentMode = .scaleAspectFill
        iconImageView.layer.cornerRadius = 8
        iconImageView.clipsToBounds = true
        iconImageView.backgroundColor = .systemGray5
        addSubview(iconImageView)
        self.iconView = iconImageView
        
        headlineLabel.translatesAutoresizingMaskIntoConstraints = false
        headlineLabel.font = .boldSystemFont(ofSize: 17)
        headlineLabel.textColor = .label
        headlineLabel.numberOfLines = 2
        addSubview(headlineLabel)
        self.headlineView = headlineLabel
        
        bodyLabel.translatesAutoresizingMaskIntoConstraints = false
        bodyLabel.font = .systemFont(ofSize: 14)
        bodyLabel.textColor = .secondaryLabel
        bodyLabel.numberOfLines = 2
        addSubview(bodyLabel)
        self.bodyView = bodyLabel
        
        adMediaView.translatesAutoresizingMaskIntoConstraints = false
        adMediaView.contentMode = .scaleAspectFit
        adMediaView.clipsToBounds = true
        addSubview(adMediaView)
        self.mediaView = adMediaView
        
        ctaButton.translatesAutoresizingMaskIntoConstraints = false
        ctaButton.setTitle("Install", for: .normal)
        ctaButton.backgroundColor = .systemBlue
        ctaButton.setTitleColor(.white, for: .normal)
        ctaButton.titleLabel?.font = .boldSystemFont(ofSize: 16)
        ctaButton.layer.cornerRadius = 12
        ctaButton.clipsToBounds = true
        ctaButton.isUserInteractionEnabled = false
        addSubview(ctaButton)
        self.callToActionView = ctaButton
        
        NSLayoutConstraint.activate([
            iconImageView.topAnchor.constraint(equalTo: topAnchor, constant: margin),
            iconImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: margin),
            iconImageView.widthAnchor.constraint(equalToConstant: 48),
            iconImageView.heightAnchor.constraint(equalToConstant: 48),
            
            headlineLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 12),
            headlineLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -margin),
            headlineLabel.topAnchor.constraint(equalTo: iconImageView.topAnchor),
            
            bodyLabel.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: 12),
            bodyLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: margin),
            bodyLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -margin),
            
            ctaButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -margin),
            ctaButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: margin),
            ctaButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -margin),
            ctaButton.heightAnchor.constraint(equalToConstant: 50),
            
            adMediaView.topAnchor.constraint(equalTo: bodyLabel.bottomAnchor, constant: 12),
            adMediaView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: margin),
            adMediaView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -margin),
            adMediaView.bottomAnchor.constraint(equalTo: ctaButton.topAnchor, constant: -12),
        ])
    }
    
    func configure(with nativeAd: NativeAd) {
        guard !isConfigured else { return }
        
        self.nativeAd = nativeAd
        
        headlineLabel.text = nativeAd.headline
        bodyLabel.text = nativeAd.body
        ctaButton.setTitle(nativeAd.callToAction ?? "Learn More", for: .normal)
        iconImageView.image = nativeAd.icon?.image
        adMediaView.mediaContent = nativeAd.mediaContent
        
        isConfigured = true
        
        setNeedsLayout()
        layoutIfNeeded()
        
        // Fix SDK-added views positioning
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            self?.fixSDKViewPositions()
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        fixSDKViewPositions()
    }
    
    /// Fixes any SDK-added views positioned at the bounds edge
    private func fixSDKViewPositions() {
        for subview in subviews {
            let typeName = String(describing: type(of: subview))
            
            if typeName.contains("GAD") || typeName.contains("Attribution") {
                var frame = subview.frame
                var needsFix = false
                
                if frame.origin.x >= bounds.width {
                    frame.origin.x = bounds.width - max(frame.width, 1) - 4
                    needsFix = true
                }
                if frame.origin.y >= bounds.height {
                    frame.origin.y = bounds.height - max(frame.height, 1) - 4
                    needsFix = true
                }
                if frame.origin.x < 0 {
                    frame.origin.x = 4
                    needsFix = true
                }
                if frame.origin.y < 0 {
                    frame.origin.y = 4
                    needsFix = true
                }
                if frame.width <= 0 || frame.height <= 0 {
                    frame = CGRect(x: 4, y: 4, width: max(frame.width, 1), height: max(frame.height, 1))
                    needsFix = true
                }
                
                if needsFix {
                    subview.frame = frame
                }
            }
        }
    }
}
