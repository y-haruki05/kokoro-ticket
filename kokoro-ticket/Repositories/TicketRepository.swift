import Foundation

@MainActor
protocol TicketRepository {
    func fetchAll() throws -> [Ticket]
    func insert(_ ticket: Ticket) throws
    func markAsUsed(id: UUID, at usedAt: Date) throws -> Bool
}
