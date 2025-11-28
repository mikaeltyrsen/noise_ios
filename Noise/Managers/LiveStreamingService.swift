import Foundation

enum LiveStreamingError: LocalizedError {
    case sdkUnavailable
    case missingAppID
    case invalidUID
    case joinFailed(Int)
    case leaveFailed(Int)
    case joinTimedOut

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
        case .leaveFailed(let code):
            return "Leaving the previous live stream failed with code \(code)."
        case .joinTimedOut:
            return "Timed out while joining the live stream."
        }
    }
}

#if canImport(AgoraRtcKit)
import AgoraRtcKit

final class LiveStreamingService: NSObject, ObservableObject {
    static let shared = LiveStreamingService()

    private var engine: AgoraRtcEngineKit?
    private var currentChannel: String?

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

        try await leaveChannelIfNeeded()

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, any Error>) in
            var hasResumed = false
            func resume(_ result: Result<Void, any Error>) {
                guard !hasResumed else { return }
                hasResumed = true
                switch result {
                case .success:
                    continuation.resume(returning: ())
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }

            let timeout = Task {
                try await Task.sleep(nanoseconds: 30_000_000_000)
                resume(.failure(LiveStreamingError.joinTimedOut))
            }

            let result = engine?.joinChannel(byToken: stream.rtcToken, channelId: stream.channel, info: nil, uid: uid) { _, _, _ in
                timeout.cancel()
                self.currentChannel = stream.channel
                resume(.success(()))
            }

            if let result {
                if result != 0 {
                    timeout.cancel()
                    resume(.failure(LiveStreamingError.joinFailed(Int(result))))
                }
            } else {
                timeout.cancel()
                resume(.failure(LiveStreamingError.joinFailed(-1)))
            }
        }
    }

    private func leaveChannelIfNeeded() async throws {
        guard let engine, currentChannel != nil else { return }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, any Error>) in
            var hasResumed = false
            func resume(_ result: Result<Void, any Error>) {
                guard !hasResumed else { return }
                hasResumed = true
                switch result {
                case .success:
                    continuation.resume(returning: ())
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }

            let result = engine.leaveChannel { _ in
                self.currentChannel = nil
                resume(.success(()))
            }

            if result != 0 {
                resume(.failure(LiveStreamingError.leaveFailed(Int(result))))
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

