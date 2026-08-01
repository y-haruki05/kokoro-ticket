import Foundation

/// フレンド検索・申請・一覧取得を提供するRepositoryの契約
@MainActor
protocol FriendRepository {
    func searchProfile(friendCode: String) async throws -> FriendSearchResult?
    func sendFriendRequest(receiverID: UUID) async throws
    func fetchIncomingRequests() async throws -> [FriendRequest]
    func fetchOutgoingRequests() async throws -> [FriendRequest]
    func acceptFriendRequest(id: UUID) async throws
    func rejectFriendRequest(id: UUID) async throws
    func fetchFriends() async throws -> [Friend]
    func fetchAvatarData(path: String) async throws -> Data
}
