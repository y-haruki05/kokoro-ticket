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
