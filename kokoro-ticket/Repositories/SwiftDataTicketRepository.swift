import Foundation
import SwiftData

/// ログイン中ユーザーの下書きをSwiftDataへ保存し、別ユーザーのデータを分離する
@MainActor
final class SwiftDataTicketRepository: TicketRepository {
    private let modelContext: ModelContext
    private let currentUserID: () -> UUID?

    init(
        modelContext: ModelContext,
        currentUserID: @escaping () -> UUID? = { nil }
    ) {
        self.modelContext = modelContext
        self.currentUserID = currentUserID
    }

    /// ownerIDで現在ユーザーのデータだけを取得し、旧形式データは一度だけ引き継ぐ
    func fetchAll() throws -> [Ticket] {
        guard let ownerID = currentUserID() else {
            return []
        }
        let descriptor = FetchDescriptor<Ticket>(
            predicate: #Predicate { ticket in
                ticket.ownerID == ownerID || ticket.ownerID == nil
            },
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        let tickets = try modelContext.fetch(descriptor)
        let legacyTickets = tickets.filter { $0.ownerID == nil }

        if !legacyTickets.isEmpty {
            legacyTickets.forEach { $0.ownerID = ownerID }
            try modelContext.save()
        }

        return tickets
    }

    func insert(_ ticket: Ticket) throws {
        guard let ownerID = currentUserID() else {
            throw AppError.authenticatedUserUnavailable
        }
        ticket.ownerID = ownerID
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

    func acknowledgeTicket(id: UUID) async throws {
        throw TicketRepositoryError.remoteUnavailable
    }

    func requestTicketUsage(id: UUID) async throws -> TicketUsageRequest {
        throw TicketRepositoryError.remoteUnavailable
    }

    func getRequestedTickets() async throws -> [TicketListItem] {
        []
    }

    func getWaitingTickets() async throws -> [TicketListItem] {
        []
    }

    func completeTicket(id: UUID) async throws {
        try complete(id: id, at: .now)
    }

    func getCompletedTickets() async throws -> [TicketListItem] {
        try fetchAll()
            .filter { $0.status == .completed }
            .map(TicketListItem.init(ticket:))
            .sorted { ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast) }
    }

    private func fetchTicket(id: UUID) throws -> Ticket {
        guard let ownerID = currentUserID() else {
            throw AppError.authenticatedUserUnavailable
        }
        let ticketID = id
        let descriptor = FetchDescriptor<Ticket>(
            predicate: #Predicate { ticket in
                ticket.id == ticketID && ticket.ownerID == ownerID
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
