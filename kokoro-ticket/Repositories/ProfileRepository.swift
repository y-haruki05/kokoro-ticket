import Foundation

@MainActor
protocol ProfileRepository {
    func fetchCurrentProfile() async throws -> Profile?
    func createProfile(displayName: String, avatarKey: String?) async throws -> Profile
    func updateDisplayName(_ displayName: String) async throws -> Profile
    func fetchAvatarData(path: String) async throws -> Data
    func updateAvatar(imageData: Data) async throws -> Profile
    func removeAvatar() async throws -> Profile
    func isFriendCodeAvailable(_ friendCode: String) async throws -> Bool
    func reloadCurrentProfile() async throws -> Profile?
}
