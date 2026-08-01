import Foundation

/// 表示名・フレンドコード・アバター保存先を表すユーザープロフィール
struct Profile: Codable, Equatable, Identifiable, Sendable {
    let id: UUID
    var displayName: String
    let friendCode: String
    var avatarKey: String?
    let createdAt: Date
    var updatedAt: Date
}
