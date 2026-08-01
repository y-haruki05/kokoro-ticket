import Foundation

/// フレンド一覧と送信先選択で利用する相手の公開プロフィール
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
