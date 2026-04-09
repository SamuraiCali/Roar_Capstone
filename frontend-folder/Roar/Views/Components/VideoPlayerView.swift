import SwiftUI
import AVKit
@preconcurrency import Amplify
internal import AWSPluginsCore

class LoopingPlayerUIView: UIView {
    private let playerLayer = AVPlayerLayer()
    private var playerLooper: AVPlayerLooper?
    private var queuePlayer: AVQueuePlayer?
    var hasPlayer: Bool { queuePlayer != nil }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayer()
    }
    
    required init?(coder: CodingKey) {
        fatalError("init(coder:) has not been implemented")
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupLayer() {
        playerLayer.videoGravity = .resizeAspectFill
        layer.addSublayer(playerLayer)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = bounds
    }
    
    func playVideo(url: URL) {
        let playerItem = AVPlayerItem(url: url)
        queuePlayer = AVQueuePlayer(playerItem: playerItem)
        playerLayer.player = queuePlayer
        
        if let player = queuePlayer {
            playerLooper = AVPlayerLooper(player: player, templateItem: playerItem)
            player.play()
        }
    }
    
    func pause() {
        queuePlayer?.pause()
    }
    
    func play() {
        queuePlayer?.play()
    }
    
    func cleanup() {
        queuePlayer?.pause()
        queuePlayer?.removeAllItems()
        playerLooper?.disableLooping()
        playerLayer.player = nil
    }
}

struct VideoPlayerView: UIViewRepresentable {
    let videoKey: String?
    @Binding var isPlaying: Bool
    
    func makeUIView(context: Context) -> LoopingPlayerUIView {
        return LoopingPlayerUIView(frame: .zero)
    }
    
    func updateUIView(_ uiView: LoopingPlayerUIView, context: Context) {
        guard let key = videoKey, !key.isEmpty else {
            uiView.cleanup()
            return
        }
        
        if isPlaying {
            // Only fetch and play if we don't already have an active player
            if uiView.hasPlayer {
                uiView.play()
            } else {
                Task {
                    do {
                        let url = try await Amplify.Storage.getURL(path: .fromString(key))
                        await MainActor.run {
                            uiView.playVideo(url: url)
                        }
                    } catch {
                        print("Failed to get presigned URL for video: \(error)")
                    }
                }
            }
        } else {
            uiView.pause()
        }
    }
    
    static func dismantleUIView(_ uiView: LoopingPlayerUIView, coordinator: ()) {
        uiView.cleanup()
    }
}
