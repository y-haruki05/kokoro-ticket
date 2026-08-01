import Foundation

/// Previewとテストで認証状態をメモリ上に再現するRepository
@MainActor
final class InMemoryAuthRepository: AuthRepository {
    private var session: AuthSession?
    private var continuation: AsyncStream<AuthSession?>.Continuation?
    private let signUpRequiresEmailConfirmation: Bool

    init(
        session: AuthSession? = nil,
        signUpRequiresEmailConfirmation: Bool = false
    ) {
        self.session = session
        self.signUpRequiresEmailConfirmation = signUpRequiresEmailConfirmation
    }

    func signUp(email: String, password: String) async throws -> AuthSession? {
        if signUpRequiresEmailConfirmation {
            return nil
        }
        let session = makeSession(email: email)
        setSession(session)
        return session
    }

    func signIn(email: String, password: String) async throws -> AuthSession {
        let session = makeSession(email: email)
        setSession(session)
        return session
    }

    func signOut() async throws {
        setSession(nil)
    }

    func currentUser() async throws -> AuthUser? {
        session?.user
    }

    func restoreSession() async throws -> AuthSession? {
        session
    }

    func sessionChanges() -> AsyncStream<AuthSession?> {
        AsyncStream { continuation in
            self.continuation = continuation
            continuation.yield(session)
        }
    }

    private func setSession(_ session: AuthSession?) {
        self.session = session
        continuation?.yield(session)
    }

    private func makeSession(email: String) -> AuthSession {
        AuthSession(
            user: AuthUser(id: UUID(), email: email),
            expiresAt: .now.addingTimeInterval(3_600)
        )
    }
}
