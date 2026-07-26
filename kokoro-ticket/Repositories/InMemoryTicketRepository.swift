import Foundation

@MainActor
final class InMemoryTicketRepository: TicketRepository {
    private var tickets: [Ticket]
    private let currentUserID: UUID
    private let currentUserName: String
    private var transfers: [TicketTransfer]
    private var usageRequests: [TicketUsageRequest]
    var sendError: AppError?

    init(
        tickets: [Ticket] = [],
        currentUserID: UUID = UUID(),
        currentUserName: String = "ゆうせい",
        transfers: [TicketTransfer] = [],
        usageRequests: [TicketUsageRequest] = [],
        sendError: AppError? = nil
    ) {
        self.tickets = tickets
        self.currentUserID = currentUserID
        self.currentUserName = currentUserName
        self.transfers = transfers
        self.usageRequests = usageRequests
        self.sendError = sendError
    }

    func fetchAll() throws -> [Ticket] {
        tickets.sorted { $0.updatedAt > $1.updatedAt }
    }

    func insert(_ ticket: Ticket) throws {
        tickets.append(ticket)
    }

    func updateDraft(
        id: UUID,
        title: String,
        message: String,
        at updatedAt: Date
    ) throws {
        let ticket = try fetchTicket(id: id)
        try require(ticket, status: .draft)
        ticket.ticketTitle = title
        ticket.message = message
        ticket.updatedAt = updatedAt
    }

    func deleteDraft(id: UUID) throws {
        let ticket = try fetchTicket(id: id)
        try require(ticket, status: .draft)
        tickets.removeAll { $0.id == id }
    }

    func send(id: UUID, to friend: Friend, at sentAt: Date) throws {
        let ticket = try fetchTicket(id: id)
        try require(ticket, status: .draft)
        ticket.receiverName = friend.displayName
        ticket.sentAt = sentAt
        transition(ticket, to: .sent, at: sentAt)
    }

    func receive(id: UUID, at receivedAt: Date) throws {
        let ticket = try fetchTicket(id: id)
        try require(ticket, status: .sent)
        ticket.receivedAt = receivedAt
        transition(ticket, to: .received, at: receivedAt)
    }

    func requestUsage(id: UUID, at requestedAt: Date) throws {
        let ticket = try fetchTicket(id: id)
        try require(ticket, status: .received)
        ticket.requestedAt = requestedAt
        transition(ticket, to: .requested, at: requestedAt)
    }

    func complete(id: UUID, at completedAt: Date) throws {
        let ticket = try fetchTicket(id: id)
        try require(ticket, status: .requested)
        ticket.completedAt = completedAt
        transition(ticket, to: .completed, at: completedAt)
    }

    func sendTicket(
        _ item: TicketListItem,
        to friend: Friend,
        at sentAt: Date
    ) async throws -> TicketTransfer {
        if let sendError { throw sendError }
        try send(id: item.id, to: friend, at: sentAt)
        let transfer = TicketTransfer(
            id: UUID(),
            ticketID: item.id,
            senderID: currentUserID,
            receiverID: friend.id,
            senderNameSnapshot: currentUserName,
            receiverNameSnapshot: friend.displayName,
            sentAt: sentAt,
            receivedAt: sentAt
        )
        transfers.append(transfer)
        return transfer
    }

    func getSentTickets() async throws -> [TicketListItem] {
        tickets
            .filter { [.sent, .received, .requested].contains($0.status) }
            .map { TicketListItem(ticket: $0).viewed(as: .sender) }
    }

    func getReceivedTickets() async throws -> [TicketListItem] {
        tickets
            .filter { [.sent, .received, .requested].contains($0.status) }
            .map { TicketListItem(ticket: $0).viewed(as: .receiver) }
    }

    func acknowledgeTicket(id: UUID) async throws {
        try receive(id: id, at: .now)
    }

    func requestTicketUsage(id: UUID) async throws -> TicketUsageRequest {
        let requestedAt = Date.now
        try requestUsage(id: id, at: requestedAt)
        let request = TicketUsageRequest(
            id: UUID(),
            ticketID: id,
            requesterID: currentUserID,
            requestedAt: requestedAt,
            completedBy: nil,
            completedAt: nil
        )
        usageRequests.append(request)
        return request
    }

    func getRequestedTickets() async throws -> [TicketListItem] {
        tickets
            .filter { $0.status == .requested }
            .map { TicketListItem(ticket: $0).viewed(as: .receiver) }
    }

    func getWaitingTickets() async throws -> [TicketListItem] {
        tickets
            .filter { $0.status == .requested }
            .map { TicketListItem(ticket: $0).viewed(as: .sender) }
    }

    private func fetchTicket(id: UUID) throws -> Ticket {
        guard let ticket = tickets.first(where: { $0.id == id }) else {
            throw TicketRepositoryError.ticketNotFound
        }
        return ticket
    }

    private func require(_ ticket: Ticket, status: TicketStatus) throws {
        guard ticket.status == status else {
            throw TicketRepositoryError.invalidTransition(
                expected: status,
                actual: ticket.status
            )
        }
    }

    private func transition(
        _ ticket: Ticket,
        to status: TicketStatus,
        at date: Date
    ) {
        ticket.status = status
        ticket.updatedAt = date
    }
}
