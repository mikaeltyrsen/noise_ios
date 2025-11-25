import Foundation

enum APIEnvironment {
    static var baseURL: URL {
        #if targetEnvironment(simulator)
        return URL(string: "http://dev.local.makenoise.app/api/v1/")!
        #else
        return URL(string: "https://makenoise.app/api/v1/")!
        #endif
    }
}

struct APIUser: Decodable {
    let id: String
    let name: String
    let email: String
}

struct LoginResponse: Decodable {
    let success: Bool
    let token: String?
    let user: APIUser?
    let message: String?
}

enum APIClientError: LocalizedError {
    case invalidCredentials
    case invalidResponse
    case serverError

    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Invalid email or password."
        case .invalidResponse:
            return "Unable to process server response."
        case .serverError:
            return "Something went wrong. Please try again."
        }
    }
}

final class APIClient {
    static let shared = APIClient()

    private let session: URLSession
    private(set) var authToken: String?

    init(session: URLSession = .shared) {
        self.session = session
    }

    func login(email: String, password: String) async throws -> LoginResponse {
        let url = APIEnvironment.baseURL.appendingPathComponent("auth/login.php")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let body: [String: String] = [
            "email": email,
            "password": password
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIClientError.invalidResponse
        }

        if httpResponse.statusCode == 401 {
            throw APIClientError.invalidCredentials
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIClientError.serverError
        }

        let decoder = JSONDecoder()
        let loginResponse = try decoder.decode(LoginResponse.self, from: data)

        guard loginResponse.success, let token = loginResponse.token else {
            throw APIClientError.invalidCredentials
        }

        authToken = token
        return loginResponse
    }

    func authorizedRequest(for path: String, method: String = "GET") throws -> URLRequest {
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
