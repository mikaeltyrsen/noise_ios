import Foundation

@MainActor
final class HomeFeedViewModel: ObservableObject {
    @Published var liveBroadcasts: [LiveBroadcast] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    func fetchFeed() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            let live = try await APIClient.shared.fetchLiveFeed()
            liveBroadcasts = live
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
