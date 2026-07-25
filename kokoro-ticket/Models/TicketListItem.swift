import Foundation

enum TicketListCategory: String, CaseIterable, Identifiable, Hashable {
    case received = "もらった"
    case sent = "あげた"
    case used = "使った"

    var id: Self { self }
}

enum TicketUsageStatus: String, Hashable {
    case unused = "未使用"
    case used = "使用済み"
}

struct TicketListItem: Identifiable, Hashable {
    let id: UUID
    let illustration: TicketIllustration?
    let title: String
    let message: String
    let senderName: String
    let receiverName: String
    let counterpartName: String
    let counterpartLabel: String
    let createdAt: Date
    var isUsed: Bool
    var usedAt: Date?
    let category: TicketListCategory
    let design: TicketDesign

    init(
        id: UUID = UUID(),
        illustration: TicketIllustration?,
        title: String,
        message: String,
        senderName: String,
        receiverName: String,
        counterpartName: String,
        counterpartLabel: String,
        createdAt: Date,
        status: TicketUsageStatus,
        usedAt: Date? = nil,
        category: TicketListCategory,
        design: TicketDesign
    ) {
        self.id = id
        self.illustration = illustration
        self.title = title
        self.message = message
        self.senderName = senderName
        self.receiverName = receiverName
        self.counterpartName = counterpartName
        self.counterpartLabel = counterpartLabel
        self.createdAt = createdAt
        self.isUsed = status == .used
        self.usedAt = usedAt
        self.category = category
        self.design = design
    }

    init(savedTicket: TicketCreationDraftSnapshot, createdAt: Date = .now) {
        self.init(
            illustration: savedTicket.selectedIllustration,
            title: savedTicket.content.ticketTitle,
            message: savedTicket.content.message,
            senderName: savedTicket.content.sender,
            receiverName: savedTicket.content.receiver,
            counterpartName: savedTicket.content.receiver,
            counterpartLabel: "宛先",
            createdAt: createdAt,
            status: .unused,
            category: .sent,
            design: savedTicket.design
        )
    }

    init(ticket: Ticket) {
        let category = TicketListCategory(rawValue: ticket.category) ?? .sent

        self.init(
            id: ticket.id,
            illustration: ticket.illustration.map(TicketIllustration.init(id:)),
            title: ticket.ticketTitle,
            message: ticket.message,
            senderName: ticket.sender,
            receiverName: ticket.receiver,
            counterpartName: category == .received ? ticket.sender : ticket.receiver,
            counterpartLabel: category == .received ? "差出人" : "宛先",
            createdAt: ticket.createdAt,
            status: ticket.isUsed ? .used : .unused,
            usedAt: ticket.usedAt,
            category: category,
            design: TicketDesign(
                backgroundColor: TicketBackgroundColor(rawValue: ticket.backgroundColor) ?? .white,
                borderStyle: TicketBorderStyle(rawValue: ticket.borderStyle) ?? .simple
            )
        )
    }

    var content: TicketContent {
        TicketContent(
            ticketTitle: title,
            message: message,
            sender: senderName,
            receiver: receiverName
        )
    }

    var status: TicketUsageStatus {
        isUsed ? .used : .unused
    }
}

extension Ticket {
    convenience init(
        savedTicket: TicketCreationDraftSnapshot,
        createdAt: Date = .now
    ) {
        self.init(
            ticketTitle: savedTicket.content.ticketTitle,
            message: savedTicket.content.message,
            sender: savedTicket.content.sender,
            receiver: savedTicket.content.receiver,
            illustration: savedTicket.selectedIllustration?.id,
            backgroundColor: savedTicket.design.backgroundColor.rawValue,
            borderStyle: savedTicket.design.borderStyle.rawValue,
            createdAt: createdAt,
            category: TicketListCategory.sent.rawValue
        )
    }

    convenience init(item: TicketListItem) {
        self.init(
            id: item.id,
            ticketTitle: item.title,
            message: item.message,
            sender: item.senderName,
            receiver: item.receiverName,
            illustration: item.illustration?.id,
            backgroundColor: item.design.backgroundColor.rawValue,
            borderStyle: item.design.borderStyle.rawValue,
            isUsed: item.isUsed,
            createdAt: item.createdAt,
            usedAt: item.usedAt,
            category: item.category.rawValue
        )
    }
}
