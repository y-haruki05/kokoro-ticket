import Foundation

/// Supabaseへ接続せずプロフィール操作を再現するInMemory実装
@MainActor
final class InMemoryProfileRepository: ProfileRepository {
    private let currentUserID: UUID
    private let generator: FriendCodeGenerator
    private var profile: Profile?
    private var reservedFriendCodes: Set<String>
    private var codeCandidates: [String]
    private var avatarDataByPath: [String: Data]
    private let avatarOperationDelay: Duration
    private let avatarError: AppError?

    init(
        currentUserID: UUID = UUID(),
        profile: Profile? = nil,
        reservedFriendCodes: Set<String> = [],
        codeCandidates: [String] = [],
        avatarData: Data? = nil,
        avatarOperationDelay: Duration = .zero,
        avatarError: AppError? = nil,
        generator: FriendCodeGenerator = FriendCodeGenerator()
    ) {
        self.currentUserID = currentUserID
        self.profile = profile
        self.reservedFriendCodes = reservedFriendCodes
        self.codeCandidates = codeCandidates
        avatarDataByPath = if let key = profile?.avatarKey, let avatarData {
            [key: avatarData]
        } else {
            [:]
        }
        self.avatarOperationDelay = avatarOperationDelay
        self.avatarError = avatarError
        self.generator = generator

        if let profile {
            self.reservedFriendCodes.insert(profile.friendCode)
        }
    }

    func fetchCurrentProfile() async throws -> Profile? {
        profile
    }

    func createProfile(
        displayName: String,
        avatarKey: String?
    ) async throws -> Profile {
        if let profile {
            return profile
        }

        let friendCode = try await availableFriendCode()
        let now = Date.now
        let newProfile = Profile(
            id: currentUserID,
            displayName: displayName,
            friendCode: friendCode,
            avatarKey: avatarKey,
            createdAt: now,
            updatedAt: now
        )

        profile = newProfile
        reservedFriendCodes.insert(friendCode)
        return newProfile
    }

    func updateDisplayName(_ displayName: String) async throws -> Profile {
        guard var profile else {
            throw AppError.profileNotFound
        }

        profile.displayName = displayName
        profile.updatedAt = .now
        self.profile = profile
        return profile
    }

    func fetchAvatarData(path: String) async throws -> Data {
        if avatarOperationDelay != .zero {
            try await Task.sleep(for: avatarOperationDelay)
        }
        if let avatarError {
            throw avatarError
        }
        guard let data = avatarDataByPath[path] else {
            throw AppError.profileAvatarLoadFailed
        }
        return data
    }

    func updateAvatar(imageData: Data) async throws -> Profile {
        if avatarOperationDelay != .zero {
            try await Task.sleep(for: avatarOperationDelay)
        }
        if let avatarError {
            throw avatarError
        }
        guard var profile else {
            throw AppError.profileNotFound
        }

        let oldKey = profile.avatarKey
        let key = "\(currentUserID.uuidString.lowercased())/avatar-preview.jpg"
        avatarDataByPath[key] = imageData
        if let oldKey, oldKey != key {
            avatarDataByPath.removeValue(forKey: oldKey)
        }
        profile.avatarKey = key
        profile.updatedAt = .now
        self.profile = profile
        return profile
    }

    func removeAvatar() async throws -> Profile {
        if avatarOperationDelay != .zero {
            try await Task.sleep(for: avatarOperationDelay)
        }
        if let avatarError {
            throw avatarError
        }
        guard var profile else {
            throw AppError.profileNotFound
        }

        if let key = profile.avatarKey {
            avatarDataByPath.removeValue(forKey: key)
        }
        profile.avatarKey = nil
        profile.updatedAt = .now
        self.profile = profile
        return profile
    }

    func isFriendCodeAvailable(_ friendCode: String) async throws -> Bool {
        !reservedFriendCodes.contains(friendCode)
    }

    func reloadCurrentProfile() async throws -> Profile? {
        profile
    }

    private func availableFriendCode(maxAttempts: Int = 10) async throws -> String {
        for _ in 0..<maxAttempts {
            let candidate = codeCandidates.isEmpty
                ? generator.generate()
                : codeCandidates.removeFirst()

            if try await isFriendCodeAvailable(candidate) {
                return candidate
            }
        }

        throw AppError.friendCodeGenerationFailed
    }
}
