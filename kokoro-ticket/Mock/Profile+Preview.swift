import Foundation

extension Profile {
    static let preview = Profile(
        id: UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE")!,
        displayName: "こころ",
        friendCode: "KRTK7M2P",
        avatarKey: nil,
        createdAt: .now.addingTimeInterval(-86_400),
        updatedAt: .now
    )
}
