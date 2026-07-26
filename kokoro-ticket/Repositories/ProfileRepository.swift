import Foundation

@MainActor
protocol ProfileRepository {
    func fetchCurrentProfile() async throws -> Profile?
    func createProfile(displayName: String, avatarKey: String?) async throws -> Profile
    func updateDisplayName(_ displayName: String) async throws -> Profile
    func isFriendCodeAvailable(_ friendCode: String) async throws -> Bool
    func reloadCurrentProfile() async throws -> Profile?
}
