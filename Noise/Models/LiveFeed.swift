import Foundation

struct LiveFeedResponse: Decodable {
    let success: Bool
    let followingLive: [LiveBroadcast]
    let otherLive: [LiveBroadcast]
    let message: String?

    enum CodingKeys: String, CodingKey {
        case success
        case followingLive = "following_live"
        case otherLive = "other_live"
        case message
    }
}

struct LiveBroadcast: Identifiable, Decodable, Equatable {
    let id: String
    let title: String?
    let agoraChannel: String
    let startedAt: String
    let userID: String
    let username: String
    let displayName: String?
    let avatarURL: String?
    let viewerCount: Int

    enum CodingKeys: String, CodingKey {
        case id = "stream_id"
        case title
        case agoraChannel = "agora_channel"
        case startedAt = "started_at"
        case userID = "user_id"
        case username
        case displayName = "display_name"
        case avatarURL = "avatar_url"
        case viewerCount = "viewer_count"
    }
}
