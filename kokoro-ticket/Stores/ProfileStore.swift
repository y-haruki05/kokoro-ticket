import Foundation
import Observation

@MainActor
@Observable
final class ProfileStore {
    static let maximumDisplayNameLength = 30

    private(set) var profile: Profile?
    private(set) var isLoading = true
    private(set) var error: AppError?
    private(set) var avatarData: Data?
    private(set) var pendingAvatarData: Data?
    private(set) var isAvatarLoading = false
    private(set) var isAvatarSaving = false
    private(set) var avatarError: AppError?
    private(set) var avatarFeedback: ProfileAvatarFeedback?

    var isProfileCompleted: Bool {
        profile != nil
    }

    @ObservationIgnored
    private let repository: any ProfileRepository
    @ObservationIgnored
    private let imageProcessor: any ProfileImageProcessing

    init(
        repository: any ProfileRepository,
        profile: Profile? = nil,
        isLoading: Bool = true,
        error: AppError? = nil,
        avatarData: Data? = nil,
        pendingAvatarData: Data? = nil,
        isAvatarLoading: Bool = false,
        isAvatarSaving: Bool = false,
        avatarError: AppError? = nil,
        avatarFeedback: ProfileAvatarFeedback? = nil,
        imageProcessor: any ProfileImageProcessing = ProfileImageProcessor()
    ) {
        self.repository = repository
        self.imageProcessor = imageProcessor
        self.profile = profile
        self.isLoading = isLoading
        self.error = error
        self.avatarData = avatarData
        self.pendingAvatarData = pendingAvatarData
        self.isAvatarLoading = isAvatarLoading
        self.isAvatarSaving = isAvatarSaving
        self.avatarError = avatarError
        self.avatarFeedback = avatarFeedback
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
            await loadAvatarIfNeeded()
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
            await loadAvatarIfNeeded()
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

    func prepareAvatar(from sourceData: Data) async {
        avatarError = nil
        avatarFeedback = nil
        isAvatarLoading = true
        defer { isAvatarLoading = false }

        do {
            let processor = imageProcessor
            pendingAvatarData = try await Task.detached(priority: .userInitiated) {
                try processor.prepareJPEG(from: sourceData)
            }.value
        } catch {
            pendingAvatarData = nil
            avatarError = normalizedAvatar(error, fallback: .profileAvatarInvalid)
        }
    }

    func savePendingAvatar() async {
        guard let pendingAvatarData, !isAvatarSaving else { return }

        avatarError = nil
        avatarFeedback = nil
        isAvatarSaving = true
        defer { isAvatarSaving = false }

        do {
            profile = try await repository.updateAvatar(imageData: pendingAvatarData)
            avatarData = pendingAvatarData
            self.pendingAvatarData = nil
            await refreshProfileAfterAvatarMutation()
            avatarFeedback = .saved
        } catch {
            avatarError = normalizedAvatar(error, fallback: .profileAvatarUploadFailed)
        }
    }

    func removeAvatar() async {
        guard !isAvatarSaving else { return }

        avatarError = nil
        avatarFeedback = nil
        isAvatarSaving = true
        defer { isAvatarSaving = false }

        do {
            profile = try await repository.removeAvatar()
            avatarData = nil
            pendingAvatarData = nil
            await refreshProfileAfterAvatarMutation()
            avatarFeedback = .removed
        } catch {
            avatarError = normalizedAvatar(error, fallback: .profileAvatarDeleteFailed)
        }
    }

    func discardPendingAvatar() {
        pendingAvatarData = nil
        avatarError = nil
        avatarFeedback = nil
    }

    func clearAvatarFeedback() {
        avatarFeedback = nil
    }

    func clearAvatarError() {
        avatarError = nil
    }

    func reportAvatarSelectionError(_ error: Error) {
        pendingAvatarData = nil
        avatarFeedback = nil
        avatarError = normalizedAvatar(error, fallback: .profileAvatarInvalid)
    }

    func reset() {
        profile = nil
        isLoading = false
        error = nil
        avatarData = nil
        pendingAvatarData = nil
        isAvatarLoading = false
        isAvatarSaving = false
        avatarError = nil
        avatarFeedback = nil
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

    private func loadAvatarIfNeeded() async {
        guard let avatarKey = profile?.avatarKey else {
            avatarData = nil
            return
        }

        isAvatarLoading = true
        defer { isAvatarLoading = false }
        do {
            avatarData = try await repository.fetchAvatarData(path: avatarKey)
            avatarError = nil
        } catch {
            avatarData = nil
            avatarError = normalizedAvatar(error, fallback: .profileAvatarLoadFailed)
        }
    }

    private func normalizedAvatar(_ error: Error, fallback: AppError) -> AppError {
        if let appError = error as? AppError {
            return appError
        }
        if let urlError = error as? URLError {
            return .network(description: urlError.localizedDescription)
        }
        return fallback
    }

    private func refreshProfileAfterAvatarMutation() async {
        do {
            if let refreshedProfile = try await repository.reloadCurrentProfile() {
                profile = refreshedProfile
            }
        } catch {
            // The mutation already succeeded. Keep the returned profile and avoid
            // presenting a false save failure; the next refresh retries this read.
            #if DEBUG
            print(
                "[ProfileAvatar] 保存後のプロフィール再取得に失敗しました "
                    + "type=\(String(describing: type(of: error)))"
            )
            #endif
        }
    }
}

enum ProfileAvatarFeedback: Equatable {
    case saved
    case removed
}
