import Foundation
import Supabase

@MainActor
final class SupabaseAuthRepository: AuthRepository {
    private let client: Supabase.SupabaseClient

    init(clientProvider: any SupabaseClientProviding) {
        client = clientProvider.client
    }

    func signUp(email: String, password: String) async throws -> AuthSession? {
        do {
            let response = try await client.auth.signUp(
                email: email,
                password: password
            )
            return response.session.map(AuthSession.init(session:))
        } catch {
            throw map(error, action: "登録")
        }
    }

    func signIn(email: String, password: String) async throws -> AuthSession {
        do {
            return AuthSession(
                session: try await client.auth.signIn(
                    email: email,
                    password: password
                )
            )
        } catch {
            throw map(error, action: "ログイン")
        }
    }

    func signOut() async throws {
        do {
            try await client.auth.signOut()
        } catch {
            throw map(error, action: "ログアウト")
        }
    }

    func currentUser() async throws -> AuthUser? {
        try await restoreSession()?.user
    }

    func restoreSession() async throws -> AuthSession? {
        guard client.auth.currentSession != nil else {
            return nil
        }

        do {
            return AuthSession(session: try await client.auth.session)
        } catch {
            throw map(error, action: "セッションの復元")
        }
    }

    func sessionChanges() -> AsyncStream<AuthSession?> {
        let changes = client.auth.authStateChanges

        return AsyncStream { continuation in
            let task = Task {
                for await (_, session) in changes {
                    continuation.yield(session.map(AuthSession.init(session:)))
                }
                continuation.finish()
            }

            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }

    private func map(_ error: Error, action: String) -> AppError {
        if let urlError = networkError(from: error) {
            return .network(description: urlError.localizedDescription)
        }

        return .authentication(
            description: "\(action)に失敗しました: \(error.localizedDescription)"
        )
    }

    private func networkError(from error: Error) -> URLError? {
        if let urlError = error as? URLError {
            return urlError
        }

        return (error as NSError).userInfo[NSUnderlyingErrorKey] as? URLError
    }
}

private extension AuthUser {
    init(user: Supabase.User) {
        self.init(id: user.id, email: user.email)
    }
}

private extension AuthSession {
    init(session: Supabase.Session) {
        self.init(
            user: AuthUser(user: session.user),
            expiresAt: Date(timeIntervalSince1970: session.expiresAt)
        )
    }
}
