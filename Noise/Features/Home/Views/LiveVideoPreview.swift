import SwiftUI

struct LiveVideoPreview: View {
    let stream: LiveBroadcast
    @State private var isConnected = false

    var body: some View {
        ZStack {
            ProceduralNoiseView(noiseOpacity: isConnected ? 0.25 : 0.65)
                .allowsHitTesting(false)

            #if canImport(AgoraRtcKit)
            AgoraLiveVideoView(channel: stream.agoraChannel, isConnected: $isConnected)
            #else
            Color.black.opacity(0.2)
            #endif
        }
    }
}

#if canImport(AgoraRtcKit)
import AgoraRtcKit

private struct AgoraLiveVideoView: UIViewRepresentable {
    let channel: String
    @Binding var isConnected: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(channel: channel, isConnected: $isConnected)
    }

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.clipsToBounds = true
        context.coordinator.attach(to: view)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) { }

    static func dismantleUIView(_ uiView: UIView, coordinator: Coordinator) {
        coordinator.stop()
    }

    final class Coordinator: NSObject, AgoraRtcEngineDelegate {
        let channel: String
        @Binding var isConnected: Bool

        private var engine: AgoraRtcEngineKit?
        private weak var containerView: UIView?
        private var uid: UInt = UInt.random(in: 1...999_999)

        init(channel: String, isConnected: Binding<Bool>) {
            self.channel = channel
            _isConnected = isConnected
        }

        func attach(to view: UIView) {
            containerView = view
            start()
        }

        func start() {
            guard let appID = Bundle.main.object(forInfoDictionaryKey: "AgoraAppID") as? String, !appID.isEmpty else {
                return
            }

            engine = AgoraRtcEngineKit.sharedEngine(withAppId: appID, delegate: self)
            engine?.enableVideo()
            engine?.setChannelProfile(.liveBroadcasting)
            engine?.setClientRole(.audience)
            engine?.muteAllRemoteAudioStreams(true)

            if let containerView {
                let canvas = AgoraRtcVideoCanvas()
                canvas.view = containerView
                canvas.renderMode = .hidden
                canvas.uid = 0
                engine?.setupRemoteVideo(canvas)
            }

            engine?.joinChannel(byToken: nil, channelId: channel, info: nil, uid: uid, joinSuccess: { [weak self] _, _, _ in
                DispatchQueue.main.async {
                    self?.isConnected = true
                }
            })
        }

        func stop() {
            engine?.leaveChannel(nil)
            engine = nil
            containerView = nil
        }

        func rtcEngine(_ engine: AgoraRtcEngineKit, remoteVideoStateChangedOfUid uid: UInt, state: AgoraVideoRemoteState, reason: AgoraVideoRemoteStateReason, elapsed: Int) {
            if state == .starting || state == .decoding {
                DispatchQueue.main.async { [weak self] in
                    self?.isConnected = true
                }
            }
        }
    }
}
#endif
