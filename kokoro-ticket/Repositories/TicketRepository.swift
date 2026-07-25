import Foundation

enum TicketRepositoryError: Error {
    case ticketNotFound
    case invalidTransition(expected: TicketStatus, actual: TicketStatus)
}

@MainActor
protocol TicketRepository {
    func fetchAll() throws -> [Ticket]
    func insert(_ ticket: Ticket) throws
    func updateDraft(
        id: UUID,
        title: String,
        message: String,
        at updatedAt: Date
    ) throws
    func deleteDraft(id: UUID) throws
    func send(id: UUID, to friend: Friend, at sentAt: Date) throws
    func receive(id: UUID, at receivedAt: Date) throws
    func requestUsage(id: UUID, at requestedAt: Date) throws
    func complete(id: UUID, at completedAt: Date) throws
}
