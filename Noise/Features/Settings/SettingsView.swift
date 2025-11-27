import SwiftUI
import UIKit

struct SettingsView: View {
    let user: APIUser
    var onUserUpdated: (APIUser) -> Void
    var onLogout: () -> Void

    @State private var username: String
    @State private var displayName: String
    @State private var bio: String
    @State private var website: String
    @State private var isPrivate: Bool
    @State private var avatarURL: String?

    @State private var isSaving = false
    @State private var errorMessage: String?

    @State private var avatarPreview: UIImage?
    @State private var showImageOptions = false
    @State private var imagePickerSource: UIImagePickerController.SourceType = .photoLibrary
    @State private var showImagePicker = false

    init(user: APIUser, onUserUpdated: @escaping (APIUser) -> Void, onLogout: @escaping () -> Void) {
        self.user = user
        self.onUserUpdated = onUserUpdated
        self.onLogout = onLogout

        _username = State(initialValue: user.username)
        _displayName = State(initialValue: user.displayName ?? "")
        _bio = State(initialValue: user.bio ?? "")
        _website = State(initialValue: user.website ?? "")
        _isPrivate = State(initialValue: user.isPrivate)
        _avatarURL = State(initialValue: user.avatarURL)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(spacing: 12) {
                        EditableAvatarView(image: avatarPreview, remoteURL: avatarURL) {
                            showImageOptions = true
                        }
                        Text("Change Photo")
                            .font(.headline)
                            .foregroundColor(.accentColor)
                            .onTapGesture { showImageOptions = true }
                    }
                    .frame(maxWidth: .infinity)
                }
                .listRowInsets(EdgeInsets())
                .frame(maxWidth: .infinity)

                Section {
                    TextField("Username", text: $username)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    TextField("Display Name", text: $displayName)
                    TextField("Bio", text: $bio, prompt: Text("Tell the world about you"))
                    TextField("Website", text: $website)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                }

                Section {
                    Toggle("Private", isOn: $isPrivate)
                }

                Section {
                    Button(role: .destructive, action: onLogout) {
                        Text("Logout")
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isSaving {
                        ProgressView()
                    } else {
                        Button("Save") {
                            Task { await saveSettings() }
                        }
                    }
                }
            }
            .alert(
                "Error",
                isPresented: Binding(
                    get: { errorMessage != nil },
                    set: { if !$0 { errorMessage = nil } }
                ),
                actions: {
                    Button("OK", role: .cancel) { errorMessage = nil }
                },
                message: {
                    if let message = errorMessage { Text(message) }
                }
            )
            .confirmationDialog("Update Avatar", isPresented: $showImageOptions, titleVisibility: .visible) {
                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                    Button("Take Photo") {
                        imagePickerSource = .camera
                        showImagePicker = true
                    }
                }
                Button("Choose from Library") {
                    imagePickerSource = .photoLibrary
                    showImagePicker = true
                }
                Button("Cancel", role: .cancel) { }
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(sourceType: imagePickerSource) { image in
                    Task { await uploadAvatar(image) }
                }
            }
        }
    }

    private func saveSettings() async {
        await MainActor.run { isSaving = true }
        defer { Task { await MainActor.run { isSaving = false } } }

        do {
            let updatedUser = try await APIClient.shared.updateSettings(
                username: username,
                displayName: displayName.isEmpty ? nil : displayName,
                bio: bio.isEmpty ? nil : bio,
                website: website.isEmpty ? nil : website,
                isPrivate: isPrivate
            )
            await MainActor.run {
                onUserUpdated(updatedUser)
                syncState(with: updatedUser)
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func uploadAvatar(_ image: UIImage) async {
        guard let jpegData = prepareAvatarData(from: image) else {
            await MainActor.run {
                errorMessage = "Unable to process image."
            }
            return
        }

        await MainActor.run {
            isSaving = true
            avatarPreview = UIImage(data: jpegData)
        }

        do {
            let updatedUser = try await APIClient.shared.uploadAvatar(imageData: jpegData)
            await MainActor.run {
                onUserUpdated(updatedUser)
                syncState(with: updatedUser)
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
            }
        }

        await MainActor.run {
            isSaving = false
        }
    }

    private func prepareAvatarData(from image: UIImage) -> Data? {
        let targetSize = CGSize(width: 512, height: 512)
        let cropped = image.cropToSquare()
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.jpegData(withCompressionQuality: 0.85) { context in
            let rect = CGRect(origin: .zero, size: targetSize)
            UIColor.white.setFill()
            context.fill(rect)
            context.cgContext.addEllipse(in: rect)
            context.cgContext.clip()
            cropped.draw(in: rect)
        }
    }

    private func syncState(with user: APIUser) {
        username = user.username
        displayName = user.displayName ?? ""
        bio = user.bio ?? ""
        website = user.website ?? ""
        isPrivate = user.isPrivate
        avatarURL = user.avatarURL
    }
}

private struct EditableAvatarView: View {
    let image: UIImage?
    let remoteURL: String?
    var onTap: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Group {
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else if let remoteURL, let url = URL(string: remoteURL) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let loaded):
                            loaded.resizable().scaledToFill()
                        case .failure:
                            placeholder
                        case .empty:
                            ProgressView()
                        @unknown default:
                            placeholder
                        }
                    }
                } else {
                    placeholder
                }
            }
            .frame(width: 120, height: 120)
            .clipShape(Circle())
            .overlay(Circle().stroke(Color.primary.opacity(0.1), lineWidth: 1))
            .shadow(radius: 4)
            .onTapGesture(perform: onTap)
        }
        .frame(maxWidth: .infinity)
    }

    private var placeholder: some View {
        Circle()
            .fill(Color.gray.opacity(0.2))
            .overlay(Image(systemName: "camera.fill").foregroundColor(.secondary))
    }
}

private struct ImagePicker: UIViewControllerRepresentable {
    var sourceType: UIImagePickerController.SourceType
    var onImagePicked: (UIImage) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        picker.allowsEditing = true
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            picker.dismiss(animated: true)
            if let edited = info[.editedImage] as? UIImage {
                parent.onImagePicked(edited)
            } else if let original = info[.originalImage] as? UIImage {
                parent.onImagePicked(original)
            }
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}

private extension UIImage {
    func cropToSquare() -> UIImage {
        let originalSize = size
        let length = min(originalSize.width, originalSize.height)
        let originX = (originalSize.width - length) / 2
        let originY = (originalSize.height - length) / 2
        let cropRect = CGRect(x: originX, y: originY, width: length, height: length)

        guard let cgImage = self.cgImage?.cropping(to: cropRect) else { return self }
        let squareImage = UIImage(cgImage: cgImage, scale: scale, orientation: imageOrientation)

        let renderer = UIGraphicsImageRenderer(size: CGSize(width: length, height: length))
        return renderer.image { _ in
            squareImage.draw(in: CGRect(origin: .zero, size: CGSize(width: length, height: length)))
        }
    }
}
