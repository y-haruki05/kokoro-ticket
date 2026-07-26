import Foundation

struct Profile: Codable, Equatable, Identifiable, Sendable {
    let id: UUID
    var displayName: String
    let friendCode: String
    var avatarKey: String?
    let createdAt: Date
    var updatedAt: Date
}
