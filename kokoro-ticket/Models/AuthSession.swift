import Foundation

/// 認証済みユーザーとセッション期限をアプリ内で扱う値
struct AuthSession: Equatable, Sendable {
    let user: AuthUser
    let expiresAt: Date
}
