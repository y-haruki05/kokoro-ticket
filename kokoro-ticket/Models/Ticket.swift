import Foundation
import SwiftData

@Model
final class Ticket {
    @Attribute(.unique) var id: UUID
    var ticketTitle: String
    var message: String
    var sender: String
    var receiver: String
    var illustration: String?
    var backgroundColor: String
    var borderStyle: String
    var isUsed: Bool
    var createdAt: Date
    var usedAt: Date?
    var category: String

    init(
        id: UUID = UUID(),
        ticketTitle: String,
        message: String,
        sender: String,
        receiver: String,
        illustration: String?,
        backgroundColor: String,
        borderStyle: String,
        isUsed: Bool = false,
        createdAt: Date = .now,
        usedAt: Date? = nil,
        category: String
    ) {
        self.id = id
        self.ticketTitle = ticketTitle
        self.message = message
        self.sender = sender
        self.receiver = receiver
        self.illustration = illustration
        self.backgroundColor = backgroundColor
        self.borderStyle = borderStyle
        self.isUsed = isUsed
        self.createdAt = createdAt
        self.usedAt = usedAt
        self.category = category
    }

    convenience init(
        id: UUID = UUID(),
        title: String,
        message: String,
        senderName: String
    ) {
        self.init(
            id: id,
            ticketTitle: title,
            message: message,
            sender: senderName,
            receiver: "",
            illustration: nil,
            backgroundColor: TicketBackgroundColor.white.rawValue,
            borderStyle: TicketBorderStyle.simple.rawValue,
            category: TicketListCategory.received.rawValue
        )
    }

    var title: String {
        ticketTitle
    }

    var senderName: String {
        sender
    }
}
