import Foundation
import SwiftData

enum TicketStatus: String, Codable, CaseIterable, Identifiable, Sendable {
    case draft
    case sent
    case received
    case requested
    case completed

    var id: Self { self }

    var displayName: String {
        switch self {
        case .draft: "保存済み"
        case .sent: "送った"
        case .received: "受け取った"
        case .requested: "リクエスト中"
        case .completed: "完了"
        }
    }

    var statusLabel: String {
        self == .requested ? "実行待ち" : displayName
    }
}

@Model
final class Ticket {
    @Attribute(.unique) var id: UUID
    var ticketTitle: String
    var message: String
    var senderName: String
    var receiverName: String?
    var illustration: String?
    var backgroundColor: String
    var borderStyle: String
    var statusRawValue: String
    var createdAt: Date
    var updatedAt: Date
    var sentAt: Date?
    var receivedAt: Date?
    var requestedAt: Date?
    var completedAt: Date?

    init(
        id: UUID = UUID(),
        ticketTitle: String,
        message: String,
        senderName: String,
        receiverName: String? = nil,
        illustration: String?,
        backgroundColor: String,
        borderStyle: String,
        status: TicketStatus = .draft,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        sentAt: Date? = nil,
        receivedAt: Date? = nil,
        requestedAt: Date? = nil,
        completedAt: Date? = nil
    ) {
        self.id = id
        self.ticketTitle = ticketTitle
        self.message = message
        self.senderName = senderName
        self.receiverName = receiverName
        self.illustration = illustration
        self.backgroundColor = backgroundColor
        self.borderStyle = borderStyle
        self.statusRawValue = status.rawValue
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.sentAt = sentAt
        self.receivedAt = receivedAt
        self.requestedAt = requestedAt
        self.completedAt = completedAt
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
            senderName: senderName,
            illustration: nil,
            backgroundColor: TicketBackgroundColor.white.rawValue,
            borderStyle: TicketBorderStyle.simple.rawValue
        )
    }

    var status: TicketStatus {
        get { TicketStatus(rawValue: statusRawValue) ?? .draft }
        set { statusRawValue = newValue.rawValue }
    }

    var title: String {
        ticketTitle
    }
}
