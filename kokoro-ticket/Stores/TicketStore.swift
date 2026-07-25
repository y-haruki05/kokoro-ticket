import Foundation
import Observation

@MainActor
@Observable
final class TicketStore {
    private(set) var tickets: [TicketListItem] = []
    private(set) var lastErrorMessage: String?

    @ObservationIgnored
    private let repository: any TicketRepository

    @ObservationIgnored
    private let localSenderName: String

    init(
        repository: any TicketRepository,
        localSenderName: String = "ゆうせい"
    ) {
        self.repository = repository
        self.localSenderName = localSenderName
        reload()
    }

    convenience init(tickets: [TicketListItem] = []) {
        self.init(
            repository: InMemoryTicketRepository(
                tickets: tickets.map(Ticket.init(item:))
            )
        )
    }

    func tickets(for status: TicketStatus) -> [TicketListItem] {
        tickets
            .filter { $0.status == status }
            .sorted { $0.updatedAt > $1.updatedAt }
    }

    func ticket(id: TicketListItem.ID) -> TicketListItem? {
        tickets.first { $0.id == id }
    }

    @discardableResult
    func add(
        savedTicket: TicketCreationDraftSnapshot,
        createdAt: Date = .now
    ) -> Bool {
        perform {
            try repository.insert(
                Ticket(
                    savedTicket: savedTicket,
                    senderName: localSenderName,
                    createdAt: createdAt
                )
            )
        }
    }

    @discardableResult
    func updateDraft(id: UUID, title: String, message: String) -> Bool {
        perform {
            try repository.updateDraft(
                id: id,
                title: title,
                message: message,
                at: .now
            )
        }
    }

    @discardableResult
    func deleteDraft(id: UUID) -> Bool {
        perform {
            try repository.deleteDraft(id: id)
        }
    }

    @discardableResult
    func send(id: UUID, to friend: Friend) -> Bool {
        perform {
            try repository.send(id: id, to: friend, at: .now)
        }
    }

    @discardableResult
    func receive(id: UUID) -> Bool {
        perform {
            try repository.receive(id: id, at: .now)
        }
    }

    @discardableResult
    func requestUsage(id: UUID) -> Bool {
        perform {
            try repository.requestUsage(id: id, at: .now)
        }
    }

    @discardableResult
    func complete(id: UUID) -> Bool {
        perform {
            try repository.complete(id: id, at: .now)
        }
    }

    func reload() {
        do {
            tickets = try repository.fetchAll().map(TicketListItem.init(ticket:))
            lastErrorMessage = nil
        } catch {
            lastErrorMessage = "チケットの読み込みに失敗しました"
        }
    }

    @discardableResult
    private func perform(_ operation: () throws -> Void) -> Bool {
        do {
            try operation()
            reload()
            return true
        } catch {
            lastErrorMessage = "チケットを更新できませんでした"
            return false
        }
    }
}
