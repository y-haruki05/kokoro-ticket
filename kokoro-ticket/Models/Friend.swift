import Foundation

struct Friend: Identifiable, Hashable, Sendable {
    let id: UUID
    let displayName: String
    let friendCode: String
    let avatarKey: String?
    let friendshipCreatedAt: Date

    init(
        id: UUID = UUID(),
        displayName: String,
        friendCode: String = "",
        avatarKey: String? = nil,
        friendshipCreatedAt: Date = .now
    ) {
        self.id = id
        self.displayName = displayName
        self.friendCode = friendCode
        self.avatarKey = avatarKey
        self.friendshipCreatedAt = friendshipCreatedAt
    }
}
