import Foundation

@MainActor
final class InMemoryFriendRepository: FriendRepository {
    private let currentUserID: UUID
    private var profiles: [FriendProfileSummary]
    private var requests: [FriendRequest]
    private var friendships: [Friend]
    var injectedError: AppError?

    init(
        currentUserID: UUID = UUID(),
        profiles: [FriendProfileSummary] = [],
        requests: [FriendRequest] = [],
        friends: [Friend] = [],
        injectedError: AppError? = nil
    ) {
        self.currentUserID = currentUserID
        self.profiles = profiles
        self.requests = requests
        friendships = friends
        self.injectedError = injectedError
    }

    func searchProfile(friendCode: String) async throws -> FriendSearchResult? {
        try failIfNeeded()
        guard let profile = profiles.first(where: {
            $0.friendCode == friendCode && $0.id != currentUserID
        }) else {
            return nil
        }

        let relationship: FriendSearchRelationship
        if friendships.contains(where: { $0.id == profile.id }) {
            relationship = .friend
        } else if requests.contains(where: {
            $0.senderID == currentUserID && $0.receiverID == profile.id && $0.status == .pending
        }) {
            relationship = .outgoingPending
        } else if requests.contains(where: {
            $0.senderID == profile.id && $0.receiverID == currentUserID && $0.status == .pending
        }) {
            relationship = .incomingPending
        } else {
            relationship = .none
        }
        return FriendSearchResult(profile: profile, relationship: relationship)
    }

    func sendFriendRequest(receiverID: UUID) async throws {
        try failIfNeeded()
        guard receiverID != currentUserID else { throw AppError.friendRequestToSelf }
        guard !friendships.contains(where: { $0.id == receiverID }) else {
            throw AppError.alreadyFriends
        }
        guard !requests.contains(where: {
            $0.senderID == currentUserID && $0.receiverID == receiverID && $0.status == .pending
        }) else {
            throw AppError.friendRequestAlreadySent
        }
        guard !requests.contains(where: {
            $0.senderID == receiverID && $0.receiverID == currentUserID && $0.status == .pending
        }) else {
            throw AppError.incomingFriendRequestExists
        }
        guard
            let sender = profiles.first(where: { $0.id == currentUserID }),
            let receiver = profiles.first(where: { $0.id == receiverID })
        else {
            throw AppError.profileNotFound
        }

        requests.append(
            FriendRequest(
                id: UUID(),
                senderID: currentUserID,
                receiverID: receiverID,
                senderProfile: sender,
                receiverProfile: receiver,
                status: .pending,
                createdAt: .now,
                respondedAt: nil
            )
        )
    }

    func fetchIncomingRequests() async throws -> [FriendRequest] {
        try failIfNeeded()
        return requests.filter { $0.receiverID == currentUserID && $0.status == .pending }
    }

    func fetchOutgoingRequests() async throws -> [FriendRequest] {
        try failIfNeeded()
        return requests.filter { $0.senderID == currentUserID && $0.status == .pending }
    }

    func acceptFriendRequest(id: UUID) async throws {
        try respond(id: id, accepted: true)
    }

    func rejectFriendRequest(id: UUID) async throws {
        try respond(id: id, accepted: false)
    }

    func fetchFriends() async throws -> [Friend] {
        try failIfNeeded()
        return friendships
    }

    private func respond(id: UUID, accepted: Bool) throws {
        try failIfNeeded()
        guard let index = requests.firstIndex(where: {
            $0.id == id && $0.receiverID == currentUserID && $0.status == .pending
        }) else {
            throw AppError.friendRequestAlreadyProcessed
        }
        let request = requests[index]
        requests[index] = FriendRequest(
            id: request.id,
            senderID: request.senderID,
            receiverID: request.receiverID,
            senderProfile: request.senderProfile,
            receiverProfile: request.receiverProfile,
            status: accepted ? .accepted : .rejected,
            createdAt: request.createdAt,
            respondedAt: .now
        )
        if accepted, !friendships.contains(where: { $0.id == request.senderID }) {
            friendships.append(
                Friend(
                    id: request.senderProfile.id,
                    displayName: request.senderProfile.displayName,
                    friendCode: request.senderProfile.friendCode,
                    avatarKey: request.senderProfile.avatarKey,
                    friendshipCreatedAt: .now
                )
            )
        }
    }

    private func failIfNeeded() throws {
        if let injectedError { throw injectedError }
    }
}
