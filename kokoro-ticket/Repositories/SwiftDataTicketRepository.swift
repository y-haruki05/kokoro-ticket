import Foundation
import SwiftData

@MainActor
final class SwiftDataTicketRepository: TicketRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func fetchAll() throws -> [Ticket] {
        let descriptor = FetchDescriptor<Ticket>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    func insert(_ ticket: Ticket) throws {
        modelContext.insert(ticket)
        try modelContext.save()
    }

    func markAsUsed(id: UUID, at usedAt: Date) throws -> Bool {
        let ticketID = id
        let descriptor = FetchDescriptor<Ticket>(
            predicate: #Predicate { ticket in
                ticket.id == ticketID
            }
        )

        guard
            let ticket = try modelContext.fetch(descriptor).first,
            !ticket.isUsed
        else {
            return false
        }

        ticket.isUsed = true
        ticket.usedAt = usedAt
        try modelContext.save()
        return true
    }
}
