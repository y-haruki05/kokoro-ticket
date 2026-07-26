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
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    func insert(_ ticket: Ticket) throws {
        modelContext.insert(ticket)
        try modelContext.save()
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
        try modelContext.save()
    }

    func deleteDraft(id: UUID) throws {
        let ticket = try fetchTicket(id: id)
        try require(ticket, status: .draft)
        modelContext.delete(ticket)
        try modelContext.save()
    }

    func send(id: UUID, to friend: Friend, at sentAt: Date) throws {
        let ticket = try fetchTicket(id: id)
        try require(ticket, status: .draft)
        ticket.receiverName = friend.displayName
        ticket.sentAt = sentAt
        transition(ticket, to: .sent, at: sentAt)
        try modelContext.save()
    }

    func receive(id: UUID, at receivedAt: Date) throws {
        let ticket = try fetchTicket(id: id)
        try require(ticket, status: .sent)
        ticket.receivedAt = receivedAt
        transition(ticket, to: .received, at: receivedAt)
        try modelContext.save()
    }

    func requestUsage(id: UUID, at requestedAt: Date) throws {
        let ticket = try fetchTicket(id: id)
        try require(ticket, status: .received)
        ticket.requestedAt = requestedAt
        transition(ticket, to: .requested, at: requestedAt)
        try modelContext.save()
    }

    func complete(id: UUID, at completedAt: Date) throws {
        let ticket = try fetchTicket(id: id)
        try require(ticket, status: .requested)
        ticket.completedAt = completedAt
        transition(ticket, to: .completed, at: completedAt)
        try modelContext.save()
    }

    func sendTicket(
        _ ticket: TicketListItem,
        to friend: Friend,
        at sentAt: Date
    ) async throws -> TicketTransfer {
        throw TicketRepositoryError.remoteUnavailable
    }

    func getSentTickets() async throws -> [TicketListItem] {
        []
    }

    func getReceivedTickets() async throws -> [TicketListItem] {
        []
    }

    private func fetchTicket(id: UUID) throws -> Ticket {
        let ticketID = id
        let descriptor = FetchDescriptor<Ticket>(
            predicate: #Predicate { ticket in
                ticket.id == ticketID
            }
        )

        guard let ticket = try modelContext.fetch(descriptor).first else {
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
