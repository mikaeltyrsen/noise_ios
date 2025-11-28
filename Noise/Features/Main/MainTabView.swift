import SwiftUI

struct MainTabView: View {
    enum Tab { case home, makeNoise, settings, search }

    @State private var currentUser: APIUser
    @State private var showMakeNoiseLive = false
    @Namespace private var gridNamespace
    @State private var selectedGridItem: LiveBroadcast? = nil

    let onLogout: () -> Void

    init(user: APIUser, onLogout: @escaping () -> Void) {
        _currentUser = State(initialValue: user)
        self.onLogout = onLogout
    }

    var body: some View {
        TabView {
            NavigationStack {
                ZStack(alignment: .bottom) {
                    HomeView(
                        user: currentUser,
                        onSelectDetail: { recording in
                            selectedGridItem = recording
                        },
                        namespace: gridNamespace
                    )
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color(.systemBackground))

                    // Floating Make Noise button
                    Button {
                        showMakeNoiseLive = true
                    } label: {
                        Text("Make Noise")
                            .font(.headline)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(Color.accentColor, in: Capsule())
                            .foregroundColor(.white)
                            .shadow(radius: 4)
                    }
                    .padding(.bottom, 16)
                }
            }
            .tabItem { Image(systemName: "house.fill") }

            NavigationStack {
                SearchView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemBackground))
            }
            .tabItem { Image(systemName: "magnifyingglass") }

            NavigationStack {
                SettingsView(
                    user: currentUser,
                    onUserUpdated: { updated in currentUser = updated },
                    onLogout: onLogout
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemBackground))
            }
            .tabItem { Image(systemName: "gearshape.fill") }
        }
        .fullScreenCover(isPresented: $showMakeNoiseLive) {
            MakeNoiseLiveView { showMakeNoiseLive = false }
                .ignoresSafeArea()
        }
        .overlay {
            if let item = selectedGridItem {
                ZStack {
                    Color.clear
                        .ignoresSafeArea()
                        .onTapGesture { selectedGridItem = nil }
                    LiveDetailView(
                        broadcast: item,
                        namespace: gridNamespace
                    ) {
                        selectedGridItem = nil
                    }
                    .ignoresSafeArea()
                }
                .zIndex(1000)
                .transition(.opacity)
                .animation(.easeInOut, value: selectedGridItem != nil)
            }
        }
    }
}

struct MakeNoiseView: View {
    let onMakeNoiseLive: () -> Void

    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                Text("Make Noise")
                    .font(.title2.bold())
                Text("Coming soon")
                    .foregroundColor(.secondary)
                Button {
                    onMakeNoiseLive()
                } label: {
                    Text("Make Noise")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.horizontal)
                }
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemBackground))
        }
    }
}

struct MakeNoiseLiveView: View {
    let onDismiss: () -> Void

    @StateObject private var viewModel = MakeNoiseLiveViewModel()
    @State private var showTitlePrompt = false
    @State private var liveTitle = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Text("Make Noise Live")
                        .font(.largeTitle.bold())
                    Text("Go live instantly and start casting to your friends.")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                }

                if viewModel.isStartingLive || viewModel.isJoiningLive {
                    ProgressView("Preparing your live stream…")
                        .progressViewStyle(.circular)
                }

                if let stream = viewModel.activeStream {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Live session ready", systemImage: "dot.radiowaves.left.and.right")
                            .font(.headline)
                        if let title = stream.title, !title.isEmpty {
                            Text("Title: \(title)")
                                .foregroundColor(.secondary)
                        }
                        Text("Channel: \(stream.channel)")
                            .foregroundColor(.secondary)
                        Text("UID: \(stream.agoraUID)")
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                }

                Spacer()

                VStack(spacing: 12) {
                    Button {
                        liveTitle = ""
                        showTitlePrompt = true
                    } label: {
                        Text("MAKE NOISE")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .disabled(viewModel.isStartingLive || viewModel.isJoiningLive)

                    Button("Dismiss") {
                        onDismiss()
                    }
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.secondarySystemBackground))
                    .foregroundColor(.primary)
                    .cornerRadius(12)
                }
            }
            .padding()
            .navigationBarHidden(true)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemBackground))
            .alert("Add a title?", isPresented: $showTitlePrompt) {
                TextField("Title (optional)", text: $liveTitle)
                Button("Skip") {
                    Task {
                        await viewModel.startLiveStream(title: nil)
                    }
                }
                Button("Go Live") {
                    let trimmed = liveTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                    Task {
                        await viewModel.startLiveStream(title: trimmed.isEmpty ? nil : trimmed)
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Name your stream or skip to start without a title.")
            }
            .alert("Unable to go live", isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { newValue in
                    if !newValue {
                        viewModel.errorMessage = nil
                    }
                }
            )) {
                Button("OK", role: .cancel) {
                    viewModel.errorMessage = nil
                }
            } message: {
                Text(viewModel.errorMessage ?? "Unknown error")
            }
        }
    }
}

struct SearchView: View {
    @State private var searchText = ""
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if searchText.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 60))
                                .foregroundColor(.secondary)
                            Text("Search Noise")
                                .font(.title2.bold())
                            Text("Find people and recordings")
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 100)
                    } else {
                        // Search results go here
                        VStack {
                            Text("Searching for: \(searchText)")
                                .foregroundColor(.secondary)
                        }
                        .padding()
                    }
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(
                text: $searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Search recordings and people"
            )
        }
    }
}

#Preview {
    MainTabView(user: APIUser(
        id: "example-id",
        email: "user@example.com",
        username: "example",
        displayName: "Example User",
        avatarURL: nil,
        status: "active",
        followerCount: 128,
        followingCount: 64,
        bio: "Bio",
        website: "https://example.com",
        isPrivate: false
    )) { }
}
