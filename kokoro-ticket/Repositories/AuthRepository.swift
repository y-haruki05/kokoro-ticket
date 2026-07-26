import Foundation

@MainActor
protocol AuthRepository {
    func signUp(email: String, password: String) async throws -> AuthSession?
    func signIn(email: String, password: String) async throws -> AuthSession
    func signOut() async throws
    func currentUser() async throws -> AuthUser?
    func restoreSession() async throws -> AuthSession?
    func sessionChanges() -> AsyncStream<AuthSession?>
}
