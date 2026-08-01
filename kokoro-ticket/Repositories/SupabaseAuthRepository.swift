import Foundation
import OSLog
import Supabase

/// Supabase Authで認証処理を実行し、SDKエラーをアプリ用エラーへ変換する
@MainActor
final class SupabaseAuthRepository: AuthRepository {
    private let client: Supabase.SupabaseClient
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "kokoro-ticket",
        category: "SupabaseAuth"
    )

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
            throw mapSignupError(error, email: email)
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
            logger.error(
                "\(action, privacy: .public) failed with network error code \(urlError.errorCode, privacy: .public)"
            )
            return .network(description: urlError.localizedDescription)
        }

        if let authError = error as? AuthError {
            logger.error(
                "\(action, privacy: .public) failed: code=\(authError.errorCode.rawValue, privacy: .public)"
            )
            switch authError.errorCode {
            case .invalidCredentials:
                return .authentication(
                    description: "メールアドレスまたはパスワードが正しくありません"
                )
            case .emailNotConfirmed:
                return .authentication(
                    description: "メール確認が完了していません。確認メール内のリンクを開いてください"
                )
            case .overRequestRateLimit:
                return .authentication(
                    description: "短時間に操作が繰り返されました。しばらく待ってからお試しください"
                )
            case .invalidJWT:
                return .authentication(
                    description: "ログインの有効期限が切れました。もう一度ログインしてください"
                )
            default:
                return .authentication(
                    description: "\(action)に失敗しました。もう一度お試しください"
                )
            }
        }

        logger.error(
            "\(action, privacy: .public) failed: type=\(String(reflecting: type(of: error)), privacy: .public)"
        )
        return .authentication(
            description: "\(action)に失敗しました。もう一度お試しください"
        )
    }

    private func mapSignupError(_ error: Error, email: String) -> AppError {
        if let urlError = networkError(from: error) {
            logger.error(
                "Sign up failed with network error code \(urlError.errorCode, privacy: .public)"
            )
            return .network(description: urlError.localizedDescription)
        }

        guard let authError = error as? AuthError else {
            let safeMessage = sanitized(error.localizedDescription, email: email)
            logger.error(
                "Sign up failed: type=\(String(reflecting: type(of: error)), privacy: .public), message=\(safeMessage, privacy: .public)"
            )
            return .authentication(
                description: "新規登録に失敗しました。もう一度お試しください"
            )
        }

        let code = authError.errorCode.rawValue
        let safeMessage = sanitized(authError.message, email: email)
        logger.error(
            "Sign up failed: type=AuthError, code=\(code, privacy: .public), message=\(safeMessage, privacy: .public)"
        )

        switch authError.errorCode {
        case .emailExists, .userAlreadyExists, .identityAlreadyExists:
            return .emailAlreadyRegistered
        case .weakPassword:
            return .passwordTooShort(minimumLength: 6)
        case .overEmailSendRateLimit, .overRequestRateLimit:
            return .signupRateLimited
        case .signupDisabled, .emailProviderDisabled, .providerDisabled:
            return .signupUnavailable
        case .captchaFailed:
            return .captchaFailed
        case .emailAddressNotAuthorized:
            return .confirmationEmailFailed
        case .validationFailed:
            return signupValidationError(message: authError.message)
        case .unexpectedFailure:
            if authError.message.localizedCaseInsensitiveContains("email") {
                return .confirmationEmailFailed
            }
            return .authentication(
                description: "新規登録に失敗しました。しばらく待ってからもう一度お試しください"
            )
        default:
            return .authentication(
                description: "新規登録に失敗しました。もう一度お試しください"
            )
        }
    }

    private func signupValidationError(message: String) -> AppError {
        let lowercased = message.lowercased()
        if lowercased.contains("email") {
            return .invalidEmail
        }
        if lowercased.contains("password") {
            return .passwordTooShort(minimumLength: 6)
        }
        return .authentication(
            description: "入力内容を確認して、もう一度お試しください"
        )
    }

    private func sanitized(_ message: String, email: String) -> String {
        message.replacingOccurrences(
            of: email,
            with: "<redacted-email>",
            options: [.caseInsensitive]
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
