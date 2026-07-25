import Foundation

@MainActor
final class InMemoryTicketRepository: TicketRepository {
    private var tickets: [Ticket]

    init(tickets: [Ticket] = []) {
        self.tickets = tickets
    }

    func fetchAll() throws -> [Ticket] {
        tickets.sorted { $0.createdAt > $1.createdAt }
    }

    func insert(_ ticket: Ticket) throws {
        tickets.append(ticket)
    }

    func markAsUsed(id: UUID, at usedAt: Date) throws -> Bool {
        guard
            let ticket = tickets.first(where: { $0.id == id }),
            !ticket.isUsed
        else {
            return false
        }

        ticket.isUsed = true
        ticket.usedAt = usedAt
        return true
    }
}
