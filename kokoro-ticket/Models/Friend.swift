import Foundation

struct Friend: Identifiable, Hashable, Sendable {
    let id: UUID
    let displayName: String

    init(id: UUID = UUID(), displayName: String) {
        self.id = id
        self.displayName = displayName
    }
}
