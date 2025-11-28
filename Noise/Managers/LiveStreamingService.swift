import Foundation

enum LiveStreamingError: LocalizedError {
    case sdkUnavailable
    case missingAppID
    case invalidUID
    case joinFailed(Int)

    var errorDescription: String? {
        switch self {
        case .sdkUnavailable:
            return "Agora SDK is not available in this build."
        case .missingAppID:
            return "Agora App ID is missing from the app configuration."
        case .invalidUID:
            return "The Agora user identifier is invalid."
        case .joinFailed(let code):
            return "Joining the live stream failed with code \(code)."
        }
    }
}

#if canImport(AgoraRtcKit)
import AgoraRtcKit

final class LiveStreamingService: NSObject, ObservableObject {
    static let shared = LiveStreamingService()

    private var engine: AgoraRtcEngineKit?

    func join(stream: LiveStreamSession) async throws {
        guard let appID = Bundle.main.object(forInfoDictionaryKey: "AgoraAppID") as? String, !appID.isEmpty else {
            throw LiveStreamingError.missingAppID
        }

        if engine == nil {
            engine = AgoraRtcEngineKit.sharedEngine(withAppId: appID, delegate: self)
            engine?.setChannelProfile(.liveBroadcasting)
            engine?.setClientRole(.broadcaster)
        }

        guard let uid = UInt(stream.agoraUID) else {
            throw LiveStreamingError.invalidUID
        }

        try await withCheckedThrowingContinuation { continuation in
            let result = engine?.joinChannel(byToken: stream.rtcToken, channelId: stream.channel, info: nil, uid: uid) { _, _, _ in
                continuation.resume(returning: ())
            }

            if let result, result != 0 {
                continuation.resume(throwing: LiveStreamingError.joinFailed(result))
            }
        }
    }
}

extension LiveStreamingService: AgoraRtcEngineDelegate { }

#else

final class LiveStreamingService: ObservableObject {
    static let shared = LiveStreamingService()

    func join(stream: LiveStreamSession) async throws {
        throw LiveStreamingError.sdkUnavailable
    }
}

#endif
