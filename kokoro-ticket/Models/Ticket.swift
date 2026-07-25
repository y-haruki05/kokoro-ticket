import Foundation

struct Ticket: Identifiable, Hashable {
    let id: UUID
    let title: String
    let message: String
    let senderName: String

    init(
        id: UUID = UUID(),
        title: String,
        message: String,
        senderName: String
    ) {
        self.id = id
        self.title = title
        self.message = message
        self.senderName = senderName
    }
}
