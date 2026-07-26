import Foundation

struct AuthUser: Equatable, Sendable {
    let id: UUID
    let email: String?
}
