import Foundation

enum FriendRequestStatus: String, Codable, Sendable {
    case pending
    case accepted
    case rejected
    case cancelled
}

struct FriendProfileSummary: Identifiable, Hashable, Sendable {
    let id: UUID
    let displayName: String
    let friendCode: String
    let avatarKey: String?
}

struct FriendRequest: Identifiable, Hashable, Sendable {
    let id: UUID
    let senderID: UUID
    let receiverID: UUID
    let senderProfile: FriendProfileSummary
    let receiverProfile: FriendProfileSummary
    let status: FriendRequestStatus
    let createdAt: Date
    let respondedAt: Date?
}

enum FriendSearchRelationship: String, Codable, Sendable {
    case none
    case outgoingPending = "outgoing_pending"
    case incomingPending = "incoming_pending"
    case friend
}

struct FriendSearchResult: Identifiable, Hashable, Sendable {
    let profile: FriendProfileSummary
    let relationship: FriendSearchRelationship

    var id: UUID { profile.id }
}
