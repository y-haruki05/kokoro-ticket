import Foundation

enum TicketDetailAction: String, Identifiable, Hashable {
    case edit
    case delete
    case send
    case acknowledgeReceipt
    case requestUsage
    case complete

    var id: Self { self }

    var title: String {
        switch self {
        case .edit: "編集"
        case .delete: "削除"
        case .send: "送信"
        case .acknowledgeReceipt: "受け取る"
        case .requestUsage: "このチケットを使う"
        case .complete: "完了にする"
        }
    }
}

enum TicketPerspective: String, Hashable, Sendable {
    case local
    case sender
    case receiver
}

struct TicketListItem: Identifiable, Hashable {
    let id: UUID
    let illustration: TicketIllustration?
    let title: String
    let message: String
    let senderName: String
    let receiverName: String?
    let createdAt: Date
    let updatedAt: Date
    let sentAt: Date?
    let receivedAt: Date?
    let requestedAt: Date?
    let completedAt: Date?
    let status: TicketStatus
    let perspective: TicketPerspective
    let design: TicketDesign

    init(
        id: UUID = UUID(),
        illustration: TicketIllustration?,
        title: String,
        message: String,
        senderName: String,
        receiverName: String? = nil,
        createdAt: Date,
        updatedAt: Date? = nil,
        sentAt: Date? = nil,
        receivedAt: Date? = nil,
        requestedAt: Date? = nil,
        completedAt: Date? = nil,
        status: TicketStatus,
        perspective: TicketPerspective = .local,
        design: TicketDesign
    ) {
        self.id = id
        self.illustration = illustration
        self.title = title
        self.message = message
        self.senderName = senderName
        self.receiverName = receiverName
        self.createdAt = createdAt
        self.updatedAt = updatedAt ?? createdAt
        self.sentAt = sentAt
        self.receivedAt = receivedAt
        self.requestedAt = requestedAt
        self.completedAt = completedAt
        self.status = status
        self.perspective = perspective
        self.design = design
    }

    init(ticket: Ticket) {
        self.init(
            id: ticket.id,
            illustration: ticket.illustration.map(TicketIllustration.init(id:)),
            title: ticket.ticketTitle,
            message: ticket.message,
            senderName: ticket.senderName,
            receiverName: ticket.receiverName,
            createdAt: ticket.createdAt,
            updatedAt: ticket.updatedAt,
            sentAt: ticket.sentAt,
            receivedAt: ticket.receivedAt,
            requestedAt: ticket.requestedAt,
            completedAt: ticket.completedAt,
            status: ticket.status,
            design: TicketDesign(
                backgroundColor: TicketBackgroundColor(rawValue: ticket.backgroundColor) ?? .white,
                borderStyle: TicketBorderStyle(rawValue: ticket.borderStyle) ?? .simple
            )
        )
    }

    var counterpartName: String {
        receiverName ?? "送り先未選択"
    }

    var counterpartLabel: String {
        receiverName == nil ? "状態" : "相手"
    }

    var detailActions: [TicketDetailAction] {
        switch (perspective, status) {
        case (_, .draft):
            [.edit, .delete, .send]
        case (.receiver, .sent):
            [.acknowledgeReceipt]
        case (.receiver, .received):
            [.requestUsage]
        case (.sender, .requested):
            [.complete]
        case (.local, .sent):
            [.acknowledgeReceipt]
        case (.local, .received):
            [.requestUsage]
        case (.local, .requested):
            [.complete]
        default:
            []
        }
    }

    var statusDisplayName: String {
        switch (perspective, status) {
        case (.sender, .requested):
            "対応待ち"
        case (.receiver, .requested):
            "相手の対応待ち"
        case (.receiver, .sent):
            "受取確認待ち"
        default:
            status.statusLabel
        }
    }

    func viewed(as perspective: TicketPerspective) -> TicketListItem {
        TicketListItem(
            id: id,
            illustration: illustration,
            title: title,
            message: message,
            senderName: senderName,
            receiverName: receiverName,
            createdAt: createdAt,
            updatedAt: updatedAt,
            sentAt: sentAt,
            receivedAt: receivedAt,
            requestedAt: requestedAt,
            completedAt: completedAt,
            status: status,
            perspective: perspective,
            design: design
        )
    }
}

extension Ticket {
    convenience init(
        savedTicket: TicketCreationDraftSnapshot,
        senderName: String,
        createdAt: Date = .now
    ) {
        self.init(
            ticketTitle: savedTicket.content.ticketTitle,
            message: savedTicket.content.message,
            senderName: senderName,
            illustration: savedTicket.selectedIllustration?.id,
            backgroundColor: savedTicket.design.backgroundColor.rawValue,
            borderStyle: savedTicket.design.borderStyle.rawValue,
            status: .draft,
            createdAt: createdAt,
            updatedAt: createdAt
        )
    }

    convenience init(item: TicketListItem) {
        self.init(
            id: item.id,
            ticketTitle: item.title,
            message: item.message,
            senderName: item.senderName,
            receiverName: item.receiverName,
            illustration: item.illustration?.id,
            backgroundColor: item.design.backgroundColor.rawValue,
            borderStyle: item.design.borderStyle.rawValue,
            status: item.status,
            createdAt: item.createdAt,
            updatedAt: item.updatedAt,
            sentAt: item.sentAt,
            receivedAt: item.receivedAt,
            requestedAt: item.requestedAt,
            completedAt: item.completedAt
        )
    }
}
