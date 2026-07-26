import Foundation
import Observation

@MainActor
@Observable
final class SessionStore {
    private(set) var session: AuthSession?
    private(set) var currentUser: AuthUser?
    private(set) var isLoading = true
    private(set) var authError: AppError?
    private(set) var registrationMessage: String?

    var isAuthenticated: Bool {
        session != nil
    }

    @ObservationIgnored
    private let repository: any AuthRepository

    @ObservationIgnored
    private var sessionTask: Task<Void, Never>?

    init(repository: any AuthRepository) {
        self.repository = repository
    }

    func restoreSession() async {
        guard sessionTask == nil else { return }

        observeSessionChanges()
        isLoading = true

        do {
            apply(try await repository.restoreSession())
            authError = nil
        } catch {
            apply(nil)
            authError = normalized(error)
        }

        isLoading = false
    }

    func signIn(email: String, password: String) async {
        guard !isLoading else { return }

        do {
            let normalizedEmail = try validatedEmail(email)
            try validatePassword(password)
            isLoading = true
            apply(
                try await repository.signIn(
                    email: normalizedEmail,
                    password: password
                )
            )
            authError = nil
        } catch {
            authError = normalized(error)
        }
        isLoading = false
    }

    func signUp(
        email: String,
        password: String,
        passwordConfirmation: String
    ) async {
        guard !isLoading else { return }

        do {
            let normalizedEmail = try validatedEmail(email)
            try validatePassword(password, minimumLength: 6)
            guard password == passwordConfirmation else {
                throw AppError.passwordMismatch
            }

            isLoading = true
            let newSession = try await repository.signUp(
                email: normalizedEmail,
                password: password
            )
            apply(newSession)
            registrationMessage = newSession == nil
                ? "確認メールを送信しました。メール内のリンクから登録を完了してください。"
                : nil
            authError = nil
        } catch {
            authError = normalized(error)
        }
        isLoading = false
    }

    func signOut() async {
        guard !isLoading else { return }

        do {
            isLoading = true
            try await repository.signOut()
            apply(nil)
            authError = nil
        } catch {
            authError = normalized(error)
        }
        isLoading = false
    }

    func clearError() {
        authError = nil
    }

    func clearRegistrationMessage() {
        registrationMessage = nil
    }

    private func observeSessionChanges() {
        sessionTask = Task { [weak self] in
            guard let self else { return }
            for await session in repository.sessionChanges() {
                guard !Task.isCancelled else { return }
                apply(session)
            }
        }
    }

    private func apply(_ session: AuthSession?) {
        self.session = session
        currentUser = session?.user
    }

    private func validatedEmail(_ email: String) throws -> String {
        try EmailAddressValidator.normalized(email)
    }

    private func validatePassword(
        _ password: String,
        minimumLength: Int? = nil
    ) throws {
        guard !password.isEmpty else {
            throw AppError.passwordRequired
        }
        if let minimumLength, password.count < minimumLength {
            throw AppError.passwordTooShort(minimumLength: minimumLength)
        }
    }

    private func normalized(_ error: Error) -> AppError {
        if let appError = error as? AppError {
            return appError
        }
        if let urlError = error as? URLError {
            return .network(description: urlError.localizedDescription)
        }
        return .authentication(description: error.localizedDescription)
    }
}
