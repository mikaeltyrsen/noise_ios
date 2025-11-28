import Foundation

enum APIEnvironment {
    static var baseURL: URL {
        #if targetEnvironment(simulator)
        return URL(string: "https://dev.server.makenoise.app/api/v1/")!
        #else
        return URL(string: "https://dev.server.makenoise.app/api/v1/")!
        #endif
    }
}

struct APIUser: Decodable {
    let id: String
    let email: String
    let username: String
    let displayName: String?
    let avatarURL: String?
    let status: String?
    let followerCount: Int
    let followingCount: Int
    let bio: String?
    let website: String?
    let isPrivate: Bool

    init(
        id: String,
        email: String,
        username: String,
        displayName: String? = nil,
        avatarURL: String? = nil,
        status: String? = nil,
        followerCount: Int = 0,
        followingCount: Int = 0,
        bio: String? = nil,
        website: String? = nil,
        isPrivate: Bool = false
    ) {
        self.id = id
        self.email = email
        self.username = username
        self.displayName = displayName
        self.avatarURL = avatarURL
        self.status = status
        self.followerCount = followerCount
        self.followingCount = followingCount
        self.bio = bio
        self.website = website
        self.isPrivate = isPrivate
    }

    enum CodingKeys: String, CodingKey {
        case id
        case email
        case username
        case displayName = "display_name"
        case avatarURL = "avatar_url"
        case status
        case followerCount = "follower_count"
        case followingCount = "following_count"
        case bio
        case website = "website_url"
        case isPrivate = "is_private"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        email = try container.decode(String.self, forKey: .email)
        username = try container.decode(String.self, forKey: .username)
        displayName = try container.decodeIfPresent(String.self, forKey: .displayName)
        avatarURL = try container.decodeIfPresent(String.self, forKey: .avatarURL)
        status = try container.decodeIfPresent(String.self, forKey: .status)
        followerCount = try container.decodeIfPresent(Int.self, forKey: .followerCount) ?? 0
        followingCount = try container.decodeIfPresent(Int.self, forKey: .followingCount) ?? 0
        bio = try container.decodeIfPresent(String.self, forKey: .bio)
        website = try container.decodeIfPresent(String.self, forKey: .website)
        isPrivate = try container.decodeIfPresent(Bool.self, forKey: .isPrivate) ?? false
    }
}

struct SessionResponse: Decodable {
    let token: String
    let expiresAt: String

    enum CodingKeys: String, CodingKey {
        case token
        case expiresAt = "expires_at"
    }
}

struct LoginResponse: Decodable {
    let success: Bool
    let session: SessionResponse?
    let token: String?
    let user: APIUser?
    let message: String?

    var resolvedToken: String? {
        session?.token ?? token
    }
}

struct CurrentUserResponse: Decodable {
    let success: Bool
    let user: APIUser?
    let message: String?
}

struct UpdateSettingsResponse: Decodable {
    let success: Bool
    let user: APIUser?
    let message: String?
}

struct LiveStartResponse: Decodable {
    let success: Bool
    let stream: LiveStreamSession?
    let message: String?
}

enum APIClientError: LocalizedError {
    case invalidCredentials
    case invalidResponse
    case serverError
    case message(String)

    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Invalid email or password."
        case .invalidResponse:
            return "Unable to process server response."
        case .serverError:
            return "Something went wrong. Please try again."
        case .message(let message):
            return message
        }
    }
}

final class APIClient {
    static let shared = APIClient()

    private let session: URLSession
    private let sessionDelegate: URLSessionDelegate?
    private let tokenStore: TokenStore
    private(set) var authToken: String?

    init(session: URLSession? = nil, tokenStore: TokenStore = .shared) {
        if let session {
            self.session = session
            self.sessionDelegate = nil
        } else {
            let (createdSession, delegate) = APIClient.makeSession()
            self.session = createdSession
            self.sessionDelegate = delegate
        }
        self.tokenStore = tokenStore
        self.authToken = tokenStore.load()
    }

    private static func makeSession() -> (URLSession, URLSessionDelegate?) {
        #if targetEnvironment(simulator)
        let delegate = DevelopmentServerTrustDelegate()
        let session = URLSession(configuration: .default, delegate: delegate, delegateQueue: nil)
        return (session, delegate)
        #else
        return (.shared, nil)
        #endif
    }

    func login(emailOrUsername: String, password: String) async throws -> LoginResponse {
        let url = APIEnvironment.baseURL.appendingPathComponent("auth/login.php")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        struct LoginRequest: Encodable {
            let emailOrUsername: String
            let password: String

            enum CodingKeys: String, CodingKey {
                case emailOrUsername = "email_or_username"
                case password
            }
        }

        let requestBody = LoginRequest(emailOrUsername: emailOrUsername, password: password)
        request.httpBody = try JSONEncoder().encode(requestBody)

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIClientError.invalidResponse
        }

        let decoder = JSONDecoder()
        let loginResponse = try decoder.decode(LoginResponse.self, from: data)

        if httpResponse.statusCode == 401 {
            if let message = loginResponse.message, !message.isEmpty {
                throw APIClientError.message(message)
            } else {
                throw APIClientError.invalidCredentials
            }
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            if let message = loginResponse.message, !message.isEmpty {
                throw APIClientError.message(message)
            }
            throw APIClientError.serverError
        }

        guard loginResponse.success, let token = loginResponse.resolvedToken else {
            if let message = loginResponse.message, !message.isEmpty {
                throw APIClientError.message(message)
            }
            throw APIClientError.invalidCredentials
        }

        authToken = token
        tokenStore.save(token)
        return loginResponse
    }

    func clearAuthToken() {
        authToken = nil
        tokenStore.clear()
    }

    func fetchCurrentUser() async throws -> APIUser {
        var request = try authorizedRequest(for: "users/me.php")
        request.httpMethod = "POST"

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIClientError.invalidResponse
        }

        let decoder = JSONDecoder()
        let userResponse = try decoder.decode(CurrentUserResponse.self, from: data)

        if httpResponse.statusCode == 401 {
            clearAuthToken()
            throw APIClientError.invalidCredentials
        }

        guard (200...299).contains(httpResponse.statusCode), userResponse.success, let user = userResponse.user else {
            if let message = userResponse.message, !message.isEmpty {
                throw APIClientError.message(message)
            }
            throw APIClientError.serverError
        }

        return user
    }

    func updateSettings(
        username: String,
        displayName: String?,
        bio: String?,
        website: String?,
        isPrivate: Bool
    ) async throws -> APIUser {
        var request = try authorizedRequest(for: "users/settings.php")
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        struct UpdateSettingsRequest: Encodable {
            let username: String
            let displayName: String?
            let bio: String?
            let website: String?
            let isPrivate: Bool

            enum CodingKeys: String, CodingKey {
                case username
                case displayName = "display_name"
                case bio
                case website = "website_url"
                case isPrivate = "is_private"
            }
        }

        let requestBody = UpdateSettingsRequest(
            username: username,
            displayName: displayName,
            bio: bio,
            website: website,
            isPrivate: isPrivate
        )
        request.httpBody = try JSONEncoder().encode(requestBody)

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIClientError.invalidResponse
        }

        let decoder = JSONDecoder()
        let result = try decoder.decode(UpdateSettingsResponse.self, from: data)

        if httpResponse.statusCode == 401 {
            clearAuthToken()
            throw APIClientError.invalidCredentials
        }

        guard (200...299).contains(httpResponse.statusCode), result.success, let user = result.user else {
            if let message = result.message, !message.isEmpty {
                throw APIClientError.message(message)
            }
            throw APIClientError.serverError
        }

        return user
    }

    func uploadAvatar(imageData: Data, filename: String = "avatar.jpg") async throws -> APIUser {
        var request = try authorizedRequest(for: "users/avatar.php")
        request.httpMethod = "POST"

        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        let body = makeMultipartBody(data: imageData, boundary: boundary, filename: filename, fieldName: "avatar")
        request.httpBody = body

        let (data, response) = try await session.upload(for: request, from: body)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIClientError.invalidResponse
        }

        let decoder = JSONDecoder()
        let result = try decoder.decode(UpdateSettingsResponse.self, from: data)

        if httpResponse.statusCode == 401 {
            clearAuthToken()
            throw APIClientError.invalidCredentials
        }

        guard (200...299).contains(httpResponse.statusCode), result.success, let user = result.user else {
            if let message = result.message, !message.isEmpty {
                throw APIClientError.message(message)
            }
            throw APIClientError.serverError
        }

        return user
    }

    func startLiveStream(title: String?) async throws -> LiveStreamSession {
        var request = try authorizedRequest(for: "live/start.php")
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        struct LiveStartRequest: Encodable {
            let title: String?
        }

        let trimmedTitle = title?.trimmingCharacters(in: .whitespacesAndNewlines)
        let payload = LiveStartRequest(title: trimmedTitle?.isEmpty == true ? nil : trimmedTitle)
        request.httpBody = try JSONEncoder().encode(payload)

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIClientError.invalidResponse
        }

        let decoder = JSONDecoder()
        let result = try decoder.decode(LiveStartResponse.self, from: data)

        if httpResponse.statusCode == 401 {
            clearAuthToken()
            throw APIClientError.invalidCredentials
        }

        guard (200...299).contains(httpResponse.statusCode), result.success, let stream = result.stream else {
            if let message = result.message, !message.isEmpty {
                throw APIClientError.message(message)
            }
            throw APIClientError.serverError
        }

        return stream
    }

    struct RegisterDeviceResponse: Decodable {
        let success: Bool
        let message: String?
    }

    /// Registers this device for push notifications on the backend.
    /// Sends device_token and platform.
    func registerDevice(deviceToken: String, platform: String = "ios") async throws {
        var request = try authorizedRequest(for: "push/register_device.php")
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        struct RegisterDeviceRequest: Encodable {
            let deviceToken: String
            let platform: String

            enum CodingKeys: String, CodingKey {
                case deviceToken = "device_token"
                case platform
            }
        }

        let payload = RegisterDeviceRequest(deviceToken: deviceToken, platform: platform)
        request.httpBody = try JSONEncoder().encode(payload)

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIClientError.invalidResponse
        }

        let decoder = JSONDecoder()
        let result = try decoder.decode(RegisterDeviceResponse.self, from: data)

        if httpResponse.statusCode == 401 {
            clearAuthToken()
            throw APIClientError.invalidCredentials
        }

        guard (200...299).contains(httpResponse.statusCode), result.success else {
            if let message = result.message, !message.isEmpty {
                throw APIClientError.message(message)
            }
            throw APIClientError.serverError
        }
    }

    func authorizedRequest(for path: String, method: String = "POST") throws -> URLRequest {
        guard let token = authToken else {
            throw APIClientError.invalidCredentials
        }

        let url = APIEnvironment.baseURL.appendingPathComponent(path)
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return request
    }

    private func makeMultipartBody(data: Data, boundary: String, filename: String, fieldName: String) -> Data {
        var body = Data()
        let lineBreak = "\r\n"

        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"\(fieldName)\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(data)
        body.append(lineBreak.data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        return body
    }
}

private final class DevelopmentServerTrustDelegate: NSObject, URLSessionDelegate {
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              challenge.protectionSpace.host == "dev.server.makenoise.app",
              let trust = challenge.protectionSpace.serverTrust else {
            completionHandler(.performDefaultHandling, nil)
            return
        }

        let credential = URLCredential(trust: trust)
        completionHandler(.useCredential, credential)
    }
}

