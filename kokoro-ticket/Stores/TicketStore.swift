import Foundation
import Observation

@MainActor
@Observable
final class TicketStore {
    private(set) var tickets: [TicketListItem] = []

    @ObservationIgnored
    private let repository: any TicketRepository

    init(repository: any TicketRepository) {
        self.repository = repository
        reload()
    }

    convenience init(tickets: [TicketListItem] = []) {
        self.init(
            repository: InMemoryTicketRepository(
                tickets: tickets.map(Ticket.init(item:))
            )
        )
    }

    func ticket(id: TicketListItem.ID) -> TicketListItem? {
        tickets.first { $0.id == id }
    }

    func add(savedTicket: TicketCreationDraftSnapshot, createdAt: Date = .now) {
        do {
            try repository.insert(
                Ticket(savedTicket: savedTicket, createdAt: createdAt)
            )
            reload()
        } catch {
            assertionFailure("チケットの保存に失敗しました: \(error)")
        }
    }

    @discardableResult
    func markAsUsed(id: TicketListItem.ID, at usedAt: Date = .now) -> Bool {
        do {
            let didUpdate = try repository.markAsUsed(id: id, at: usedAt)
            if didUpdate {
                reload()
            }
            return didUpdate
        } catch {
            assertionFailure("チケットの更新に失敗しました: \(error)")
            return false
        }
    }

    func reload() {
        do {
            tickets = try repository.fetchAll().map(TicketListItem.init(ticket:))
        } catch {
            assertionFailure("チケットの読み込みに失敗しました: \(error)")
            tickets = []
        }
    }
}
