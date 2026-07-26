import Foundation

struct FriendCodeGenerator: Sendable {
    static let allowedCharacters = Array("ABCDEFGHJKLMNPQRSTUVWXYZ23456789")

    let length: Int

    init(length: Int = 8) {
        self.length = length
    }

    func generate() -> String {
        String(
            (0..<length).compactMap { _ in
                Self.allowedCharacters.randomElement()
            }
        )
    }
}
