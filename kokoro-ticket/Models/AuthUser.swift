import Foundation

/// Supabase Authのユーザー情報から画面に必要な項目だけを保持する
struct AuthUser: Equatable, Sendable {
    let id: UUID
    let email: String?
}
