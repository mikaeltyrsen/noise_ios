import Foundation

struct LiveStreamSession: Identifiable, Decodable {
    let id: String
    let title: String?
    let channel: String
    let agoraUID: String
    let rtcToken: String
    let expiresIn: Int
    let startedAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case channel
        case agoraUID = "agora_uid"
        case rtcToken = "rtc_token"
        case expiresIn = "expires_in"
        case startedAt = "started_at"
    }
}
