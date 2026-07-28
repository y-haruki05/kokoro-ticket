import Foundation

enum FriendPreviewData {
    static let currentUserID = UUID(uuidString: "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA")!
    static let otherUserID = UUID(uuidString: "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB")!

    static let currentProfile = FriendProfileSummary(
        id: currentUserID,
        displayName: "こころ",
        friendCode: "KRTK7M2P",
        avatarKey: nil
    )
    static let otherProfile = FriendProfileSummary(
        id: otherUserID,
        displayName: "あおい",
        friendCode: "A2BC3DEF",
        avatarKey: nil
    )
    static let friend = Friend(
        id: otherUserID,
        displayName: "あおい",
        friendCode: "A2BC3DEF",
        avatarKey: nil,
        friendshipCreatedAt: .now
    )
    static let friends = [
        friend,
        Friend(
            id: UUID(uuidString: "CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCCCC")!,
            displayName: "はる",
            friendCode: "H3JK7MNP",
            avatarKey: nil,
            friendshipCreatedAt: Calendar.current.date(
                byAdding: .month,
                value: -2,
                to: .now
            ) ?? .now
        )
    ]
    static let incomingRequest = FriendRequest(
        id: UUID(),
        senderID: otherUserID,
        receiverID: currentUserID,
        senderProfile: otherProfile,
        receiverProfile: currentProfile,
        status: .pending,
        createdAt: .now,
        respondedAt: nil
    )
    static let outgoingRequest = FriendRequest(
        id: UUID(),
        senderID: currentUserID,
        receiverID: otherUserID,
        senderProfile: currentProfile,
        receiverProfile: otherProfile,
        status: .pending,
        createdAt: .now,
        respondedAt: nil
    )
    static let searchResult = FriendSearchResult(
        profile: otherProfile,
        relationship: .none
    )
}
