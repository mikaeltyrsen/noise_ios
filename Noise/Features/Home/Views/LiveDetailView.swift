import SwiftUI

struct LiveDetailView: View {
    let broadcast: LiveBroadcast
    let namespace: Namespace.ID
    var onDismiss: () -> Void

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 0)
                .fill(Color(hue: 1.0, saturation: 0.0, brightness: 0.231))
                .matchedGeometryEffect(id: broadcast.id, in: namespace)
                .overlay(LiveVideoPreview(stream: broadcast))
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Text(broadcast.title ?? broadcast.username)
                    .font(.largeTitle.bold())
                    .foregroundColor(.white)

                Button(action: onDismiss) {
                    Label("Close", systemImage: "xmark")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.black.opacity(0.35))
                        .clipShape(Capsule())
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

#Preview {
    LiveDetailPreview()
}

private struct LiveDetailPreview: View {
    @Namespace var namespace

    var body: some View {
        LiveDetailView(
            broadcast: LiveBroadcast(
                id: "example",
                title: "Example Live",
                agoraChannel: "noise_example",
                startedAt: "2024-01-01",
                userID: "user",
                username: "example",
                displayName: "Example User",
                avatarURL: nil,
                viewerCount: 12
            ),
            namespace: namespace,
            onDismiss: {}
        )
    }
}
