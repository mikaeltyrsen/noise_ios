import Foundation
import SwiftUI

@MainActor
final class MakeNoiseLiveViewModel: ObservableObject {
    @Published var isStartingLive = false
    @Published var isJoiningLive = false
    @Published var activeStream: LiveStreamSession?
    @Published var errorMessage: String?

    private let apiClient: APIClient
    private let streamingService: LiveStreamingService

    init(
        apiClient: APIClient = .shared,
        streamingService: LiveStreamingService = .shared
    ) {
        self.apiClient = apiClient
        self.streamingService = streamingService
    }

    func startLiveStream(title: String?) async {
        guard !isStartingLive else { return }

        isStartingLive = true
        errorMessage = nil

        do {
            let stream = try await apiClient.startLiveStream(title: title)
            activeStream = stream
            isJoiningLive = true

            try await streamingService.join(stream: stream)
        } catch {
            errorMessage = error.localizedDescription
        }

        isStartingLive = false
        isJoiningLive = false
    }
}
