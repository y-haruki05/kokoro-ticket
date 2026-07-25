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
    let counterpartName: String
    let counterpartLabel: String
    let createdAt: Date
    let status: TicketUsageStatus
    let category: TicketListCategory

    init(
        id: UUID = UUID(),
        illustration: TicketIllustration?,
        title: String,
        message: String,
        counterpartName: String,
        counterpartLabel: String,
        createdAt: Date,
        status: TicketUsageStatus,
        category: TicketListCategory
    ) {
        self.id = id
        self.illustration = illustration
        self.title = title
        self.message = message
        self.counterpartName = counterpartName
        self.counterpartLabel = counterpartLabel
        self.createdAt = createdAt
        self.status = status
        self.category = category
    }

    init(savedTicket: TicketCreationDraftSnapshot, createdAt: Date = .now) {
        self.init(
            illustration: savedTicket.selectedIllustration,
            title: savedTicket.content.ticketTitle,
            message: savedTicket.content.message,
            counterpartName: savedTicket.content.receiver,
            counterpartLabel: "宛先",
            createdAt: createdAt,
            status: .unused,
            category: .sent
        )
    }
}
