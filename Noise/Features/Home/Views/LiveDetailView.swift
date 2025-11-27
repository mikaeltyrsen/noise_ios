import SwiftUI

struct LiveDetailView: View {
    let recording: Recording
    let namespace: Namespace.ID
    var onDismiss: () -> Void

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 0)
                .fill(Color(hue: 1.0, saturation: 0.0, brightness: 0.231))
                .matchedGeometryEffect(id: recording.id, in: namespace)
                .overlay(ProceduralNoiseView())
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Text(recording.title)
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
            recording: Recording(id: 1, title: "Example"),
            namespace: namespace,
            onDismiss: {}
        )
    }
}
