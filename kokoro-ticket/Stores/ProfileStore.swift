import Foundation
import Observation

@MainActor
@Observable
final class ProfileStore {
    static let maximumDisplayNameLength = 30

    private(set) var profile: Profile?
    private(set) var isLoading = true
    private(set) var error: AppError?

    var isProfileCompleted: Bool {
        profile != nil
    }

    @ObservationIgnored
    private let repository: any ProfileRepository

    init(
        repository: any ProfileRepository,
        profile: Profile? = nil,
        isLoading: Bool = true,
        error: AppError? = nil
    ) {
        self.repository = repository
        self.profile = profile
        self.isLoading = isLoading
        self.error = error
    }

    func loadProfile(hasAuthenticatedUser: Bool) async {
        guard hasAuthenticatedUser else {
            reset()
            return
        }

        isLoading = true
        do {
            profile = try await repository.fetchCurrentProfile()
            error = nil
        } catch {
            profile = nil
            self.error = normalized(error)
        }
        isLoading = false
    }

    func reloadProfile() async {
        isLoading = true
        do {
            profile = try await repository.reloadCurrentProfile()
            error = nil
        } catch {
            self.error = normalized(error)
        }
        isLoading = false
    }

    func createProfile(displayName: String, avatarKey: String? = nil) async {
        do {
            let normalizedName = try normalizedDisplayName(displayName)
            isLoading = true
            profile = try await repository.createProfile(
                displayName: normalizedName,
                avatarKey: avatarKey
            )
            error = nil
        } catch {
            self.error = normalized(error)
        }
        isLoading = false
    }

    func updateDisplayName(_ displayName: String) async {
        do {
            let normalizedName = try normalizedDisplayName(displayName)
            isLoading = true
            profile = try await repository.updateDisplayName(normalizedName)
            error = nil
        } catch {
            self.error = normalized(error)
        }
        isLoading = false
    }

    func reset() {
        profile = nil
        isLoading = false
        error = nil
    }

    func clearError() {
        error = nil
    }

    private func normalizedDisplayName(_ displayName: String) throws -> String {
        let trimmed = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed.count <= Self.maximumDisplayNameLength else {
            throw AppError.invalidDisplayName
        }
        return trimmed
    }

    private func normalized(_ error: Error) -> AppError {
        if let appError = error as? AppError {
            return appError
        }
        if let urlError = error as? URLError {
            return .network(description: urlError.localizedDescription)
        }
        return .profile(description: error.localizedDescription)
    }
}
