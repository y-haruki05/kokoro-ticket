import Foundation
import OSLog
import Supabase

/// RLSで保護されたRPCを介してフレンド検索・申請・承認を実行する
@MainActor
final class SupabaseFriendRepository: FriendRepository {
    private static let avatarBucket = "profile-avatars"
    private let client: Supabase.SupabaseClient
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "kokoro-ticket",
        category: "FriendRepository"
    )

    init(clientProvider: any SupabaseClientProviding) {
        client = clientProvider.client
    }

    func searchProfile(friendCode: String) async throws -> FriendSearchResult? {
        do {
            let records: [FriendSearchRecord] = try await client
                .rpc("search_profile_by_friend_code", params: ["input_friend_code": friendCode])
                .execute()
                .value
            return records.first.map(FriendSearchResult.init(record:))
        } catch {
            throw map(error, action: "フレンド検索")
        }
    }

    func sendFriendRequest(receiverID: UUID) async throws {
        do {
            let result: String = try await client
                .rpc("send_friend_request", params: ["target_receiver_id": receiverID])
                .execute()
                .value
            switch result {
            case "sent":
                return
            case "already_friends":
                throw AppError.alreadyFriends
            case "already_sent":
                throw AppError.friendRequestAlreadySent
            case "incoming_pending":
                throw AppError.incomingFriendRequestExists
            case "self_request":
                throw AppError.friendRequestToSelf
            default:
                throw AppError.friend(description: "フレンド申請を送信できませんでした")
            }
        } catch {
            throw map(error, action: "フレンド申請")
        }
    }

    func fetchIncomingRequests() async throws -> [FriendRequest] {
        try await fetchRequests(function: "get_incoming_friend_requests")
    }

    func fetchOutgoingRequests() async throws -> [FriendRequest] {
        try await fetchRequests(function: "get_outgoing_friend_requests")
    }

    func acceptFriendRequest(id: UUID) async throws {
        try await respond(id: id, action: "accept")
    }

    func rejectFriendRequest(id: UUID) async throws {
        try await respond(id: id, action: "reject")
    }

    func fetchFriends() async throws -> [Friend] {
        do {
            let records: [FriendRecord] = try await client
                .rpc("get_friends")
                .execute()
                .value
            return records.map(Friend.init(record:))
        } catch {
            throw map(error, action: "フレンド一覧の取得")
        }
    }

    func fetchAvatarData(path: String) async throws -> Data {
        do {
            return try await client.storage
                .from(Self.avatarBucket)
                .download(path: path)
        } catch {
            throw map(error, action: "プロフィール画像の取得")
        }
    }

    private func fetchRequests(function: String) async throws -> [FriendRequest] {
        do {
            let records: [FriendRequestRecord] = try await client
                .rpc(function)
                .execute()
                .value
            return records.map(FriendRequest.init(record:))
        } catch {
            throw map(error, action: "フレンド申請一覧の取得")
        }
    }

    private func respond(id: UUID, action: String) async throws {
        do {
            let result: String = try await client
                .rpc(
                    "respond_friend_request",
                    params: [
                        "target_request_id": id.uuidString,
                        "response_action": action
                    ]
                )
                .execute()
                .value
            guard result == (action == "accept" ? "accepted" : "rejected") else {
                throw AppError.friendRequestAlreadyProcessed
            }
        } catch {
            throw map(error, action: "フレンド申請の処理")
        }
    }

    private func map(_ error: Error, action: String) -> AppError {
        if let appError = error as? AppError {
            return appError
        }
        if let urlError = networkError(from: error) {
            return .network(description: urlError.localizedDescription)
        }

        let detail = String(reflecting: error)
        logger.error("\(action, privacy: .public) failed: \(detail, privacy: .public)")
        let normalized = detail.lowercased()

        if normalized.contains("42501") || normalized.contains("permission") || normalized.contains("row-level") {
            return .friendPermissionDenied
        }
        if normalized.contains("already_friends") {
            return .alreadyFriends
        }
        if normalized.contains("already_sent") {
            return .friendRequestAlreadySent
        }
        if normalized.contains("incoming_pending") {
            return .incomingFriendRequestExists
        }
        if normalized.contains("self_request") {
            return .friendRequestToSelf
        }
        if normalized.contains("already_processed") {
            return .friendRequestAlreadyProcessed
        }
        return .friend(description: "\(action)に失敗しました")
    }

    private func networkError(from error: Error) -> URLError? {
        if let urlError = error as? URLError { return urlError }
        return (error as NSError).userInfo[NSUnderlyingErrorKey] as? URLError
    }
}

private struct FriendSearchRecord: Decodable {
    let profileID: UUID
    let displayName: String
    let friendCode: String
    let avatarKey: String?
    let relationship: FriendSearchRelationship

    enum CodingKeys: String, CodingKey {
        case profileID = "profile_id"
        case displayName = "display_name"
        case friendCode = "friend_code"
        case avatarKey = "avatar_key"
        case relationship
    }
}

private struct FriendRequestRecord: Decodable {
    let requestID: UUID
    let senderID: UUID
    let receiverID: UUID
    let senderDisplayName: String
    let senderFriendCode: String
    let senderAvatarKey: String?
    let receiverDisplayName: String
    let receiverFriendCode: String
    let receiverAvatarKey: String?
    let status: FriendRequestStatus
    let createdAt: Date
    let respondedAt: Date?

    enum CodingKeys: String, CodingKey {
        case requestID = "request_id"
        case senderID = "sender_id"
        case receiverID = "receiver_id"
        case senderDisplayName = "sender_display_name"
        case senderFriendCode = "sender_friend_code"
        case senderAvatarKey = "sender_avatar_key"
        case receiverDisplayName = "receiver_display_name"
        case receiverFriendCode = "receiver_friend_code"
        case receiverAvatarKey = "receiver_avatar_key"
        case status
        case createdAt = "created_at"
        case respondedAt = "responded_at"
    }
}

private struct FriendRecord: Decodable {
    let profileID: UUID
    let displayName: String
    let friendCode: String
    let avatarKey: String?
    let friendshipCreatedAt: Date

    enum CodingKeys: String, CodingKey {
        case profileID = "profile_id"
        case displayName = "display_name"
        case friendCode = "friend_code"
        case avatarKey = "avatar_key"
        case friendshipCreatedAt = "friendship_created_at"
    }
}

private extension FriendSearchResult {
    init(record: FriendSearchRecord) {
        self.init(
            profile: FriendProfileSummary(
                id: record.profileID,
                displayName: record.displayName,
                friendCode: record.friendCode,
                avatarKey: record.avatarKey
            ),
            relationship: record.relationship
        )
    }
}

private extension FriendRequest {
    init(record: FriendRequestRecord) {
        self.init(
            id: record.requestID,
            senderID: record.senderID,
            receiverID: record.receiverID,
            senderProfile: FriendProfileSummary(
                id: record.senderID,
                displayName: record.senderDisplayName,
                friendCode: record.senderFriendCode,
                avatarKey: record.senderAvatarKey
            ),
            receiverProfile: FriendProfileSummary(
                id: record.receiverID,
                displayName: record.receiverDisplayName,
                friendCode: record.receiverFriendCode,
                avatarKey: record.receiverAvatarKey
            ),
            status: record.status,
            createdAt: record.createdAt,
            respondedAt: record.respondedAt
        )
    }
}

private extension Friend {
    init(record: FriendRecord) {
        self.init(
            id: record.profileID,
            displayName: record.displayName,
            friendCode: record.friendCode,
            avatarKey: record.avatarKey,
            friendshipCreatedAt: record.friendshipCreatedAt
        )
    }
}
