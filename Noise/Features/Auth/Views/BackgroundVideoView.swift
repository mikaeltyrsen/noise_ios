import SwiftUI
import AVKit

struct BackgroundVideoView: View {
    let videoName: String

    @State private var player = AVQueuePlayer()
    @State private var looper: AVPlayerLooper?

    var body: some View {
        VideoPlayer(player: player)
            .ignoresSafeArea()
            .allowsHitTesting(false)
            .onAppear {
                guard looper == nil, let url = Bundle.main.url(forResource: videoName, withExtension: "mp4") else { return }

                let item = AVPlayerItem(url: url)
                looper = AVPlayerLooper(player: player, templateItem: item)
                player.isMuted = true
                player.play()
            }
            .onDisappear {
                player.pause()
                player.removeAllItems()
                looper = nil
            }
    }
}
