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

    @State private var imageForCropPreview: UIImage? = nil
    @State private var showCropPreview = false

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

    private var hasUnsavedChanges: Bool {
        username != user.username ||
        (displayName != (user.displayName ?? "")) ||
        (bio != (user.bio ?? "")) ||
        (website != (user.website ?? "")) ||
        isPrivate != user.isPrivate
    }

    var body: some View {
        NavigationStack {
            Form {
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
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 16, leading: 0, bottom: 8, trailing: 0))
                .listRowSeparator(.hidden)

                Section(header: Text("Profile")) {
                    // Username
                    NavigationLink {
                        EditTextFieldView(
                            title: "Edit Username",
                            fieldLabel: "Username",
                            initialText: username
                        ) { newValue async throws in
                            username = newValue
                            try await saveSettingsThrowing()
                        }
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Username")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                            HStack(spacing: 4) {
                                Image(systemName: "at")
                                    .foregroundStyle(.secondary)
                                Text(username.isEmpty ? "Not set" : username)
                                    .foregroundStyle(username.isEmpty ? .secondary : .primary)
                            }
                        }
                    }

                    // Display Name
                    NavigationLink {
                        EditTextFieldView(
                            title: "Edit Display Name",
                            fieldLabel: "Display Name",
                            initialText: displayName
                        ) { newValue async throws in
                            displayName = newValue
                            try await saveSettingsThrowing()
                        }
                    } label: {
                        HStack(spacing: 12) {
                            // No leading icon for display name
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Display Name")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                                Text(displayName.isEmpty ? "Not set" : displayName)
                                    .foregroundStyle(displayName.isEmpty ? .secondary : .primary)
                            }
                        }
                    }

                    // Bio
                    NavigationLink {
                        EditTextFieldView(
                            title: "Edit Bio",
                            fieldLabel: "Bio",
                            initialText: bio
                        ) { newValue async throws in
                            bio = newValue
                            try await saveSettingsThrowing()
                        }
                    } label: {
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Bio")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                                Text(bio.isEmpty ? "Not set" : bio)
                                    .foregroundStyle(bio.isEmpty ? .secondary : .primary)
                            }
                        }
                    }

                    // Website
                    NavigationLink {
                        EditTextFieldView(
                            title: "Edit Website",
                            fieldLabel: "Website",
                            initialText: website
                        ) { newValue async throws in
                            website = newValue
                            try await saveSettingsThrowing()
                        }
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Website")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                            HStack(spacing: 4) {
                                Image(systemName: "link")
                                    .foregroundStyle(.secondary)
                                Text(website.isEmpty ? "Not set" : website)
                                    .foregroundStyle(website.isEmpty ? .secondary : .primary)
                            }
                        }
                    }
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
            .toolbar { }
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
                    imageForCropPreview = image
                }
            }
            .onChange(of: showImagePicker) { _, newValue in
                if !newValue, imageForCropPreview != nil {
                    showCropPreview = true
                }
            }
            .sheet(isPresented: $showCropPreview) {
                if let cropImage = imageForCropPreview {
                    CircularCropPreview(image: cropImage, onUsePhoto: { cropped in
                        Task {
                            showCropPreview = false
                            await uploadAvatar(cropped)
                            imageForCropPreview = nil
                        }
                    }, onCancel: {
                        showCropPreview = false
                        imageForCropPreview = nil
                    })
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

    private func saveSettingsThrowing() async throws {
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
            throw error
        }
    }

    private func uploadAvatar(_ image: UIImage) async {
        let croppedImage = image.cropToSquare()
        guard let jpegData = prepareAvatarData(from: croppedImage) else {
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

    /// Crops and resizes the image to a 512x512 JPEG.
    private func prepareAvatarData(from image: UIImage) -> Data? {
        let targetSize = CGSize(width: 512, height: 512)
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.jpegData(withCompressionQuality: 0.85) { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
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

struct EditTextFieldView: View {
    let title: String
    let fieldLabel: String
    @State private var text: String
    @State private var isSaving: Bool = false
    @State private var hasChanges: Bool = false
    @State private var errorMessage: String? = nil
    @State private var fieldError: String? = nil
    @FocusState private var isFocused: Bool

    @Environment(\.dismiss) private var dismiss

    let initialTextValue: String
    let onSave: (String) async throws -> Void

    init(title: String, fieldLabel: String, initialText: String, onSave: @escaping (String) async throws -> Void) {
        self.title = title
        self.fieldLabel = fieldLabel
        self.initialTextValue = initialText
        _text = State(initialValue: initialText)
        self.onSave = onSave
    }

    var body: some View {
        Form {
            Section(header: Text(fieldLabel)) {
                TextField(fieldLabel, text: $text)
                    .focused($isFocused)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .onChange(of: text) { newValue in
                        hasChanges = (newValue != initialTextValue)
                        if fieldError != nil { fieldError = nil }
                    }
                if let fieldError {
                    Text(fieldError)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // Show spinner only while saving
            if isSaving {
                ToolbarItem(placement: .topBarTrailing) {
                    ProgressView()
                        .opacity(1)
                        .scaleEffect(1)
                        .animation(
                            .spring(response: 0.35, dampingFraction: 0.8, blendDuration: 0.2),
                            value: isSaving
                        )
                }
            }

            // Show Save only when there are changes and not saving
            if hasChanges && !isSaving {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        isSaving = true
                        Task {
                            do {
                                try await onSave(text)
                                isSaving = false
                                hasChanges = false
                                dismiss()
                            } catch {
                                isSaving = false
                                let nsError = error as NSError
                                let isNetworkOrSystem = nsError.domain == NSURLErrorDomain || nsError.domain == NSCocoaErrorDomain
                                if isNetworkOrSystem {
                                    errorMessage = error.localizedDescription
                                } else {
                                    fieldError = error.localizedDescription.isEmpty ? "Something went wrong." : error.localizedDescription
                                }
                            }
                        }
                    }
                    .bold()
                    .opacity(1)
                    .scaleEffect(1)
                    .animation(
                        .spring(response: 0.35, dampingFraction: 0.8, blendDuration: 0.2),
                        value: hasChanges
                    )
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
        .task {
            // Delay a tick to ensure the field is in the view hierarchy before focusing
            await MainActor.run { isFocused = true }
        }
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

/// Circular crop preview with mask and confirm/cancel.
struct CircularCropPreview: View {
    let image: UIImage
    var onUsePhoto: (UIImage) -> Void
    var onCancel: () -> Void

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                let cropSize = max(min(geo.size.width, geo.size.height) - 40, 200)
                ZStack {
                    Color.black.ignoresSafeArea()
                    VStack {
                        Spacer()
                        ZStack {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: cropSize, height: cropSize)
                                .clipped()
                            CircleCropMask(size: cropSize)
                        }
                        .frame(width: cropSize, height: cropSize)
                        Spacer()
                    }
                }
                .navigationTitle("Crop Photo")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel", role: .cancel, action: onCancel)
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            let cropped = cropVisualSquare(from: image, cropSize: cropSize)
                            onUsePhoto(cropped)
                        }
                    }
                }
            }
        }
    }

    // Mask overlay: transparent circle in center, dimmed outside
    private struct CircleCropMask: View {
        let size: CGFloat
        var body: some View {
            ZStack {
                Color.black
                Circle()
                    .frame(width: size * 0.94, height: size * 0.94)
                    .blendMode(.destinationOut)
            }
            .compositingGroup()
        }
    }

    private func cropVisualSquare(from image: UIImage, cropSize: CGFloat) -> UIImage {
        let width = image.size.width
        let height = image.size.height
        let side = min(width, height)
        let originX = (width - side) / 2
        let originY = (height - side) / 2
        guard let cgImage = image.cgImage?.cropping(to: CGRect(x: originX, y: originY, width: side, height: side)) else {
            return image
        }
        let squareImage = UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: cropSize, height: cropSize))
        return renderer.image { _ in
            squareImage.draw(in: CGRect(origin: .zero, size: CGSize(width: cropSize, height: cropSize)))
        }
    }
}
