import Foundation

struct AuthSession: Equatable, Sendable {
    let user: AuthUser
    let expiresAt: Date
}
