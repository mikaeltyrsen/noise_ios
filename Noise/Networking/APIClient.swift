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

    init(
        id: String,
        email: String,
        username: String,
        displayName: String? = nil,
        avatarURL: String? = nil,
        status: String? = nil,
        followerCount: Int = 0,
        followingCount: Int = 0
    ) {
        self.id = id
        self.email = email
        self.username = username
        self.displayName = displayName
        self.avatarURL = avatarURL
        self.status = status
        self.followerCount = followerCount
        self.followingCount = followingCount
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
