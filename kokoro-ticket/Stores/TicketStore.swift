import Foundation
import Observation

@Observable
final class TicketStore {
    private(set) var tickets: [TicketListItem]

    init(tickets: [TicketListItem] = []) {
        self.tickets = tickets
    }

    func ticket(id: TicketListItem.ID) -> TicketListItem? {
        tickets.first { $0.id == id }
    }

    func add(savedTicket: TicketCreationDraftSnapshot, createdAt: Date = .now) {
        tickets.append(
            TicketListItem(savedTicket: savedTicket, createdAt: createdAt)
        )
    }

    @discardableResult
    func markAsUsed(id: TicketListItem.ID, at usedAt: Date = .now) -> Bool {
        guard
            let index = tickets.firstIndex(where: { $0.id == id }),
            !tickets[index].isUsed
        else {
            return false
        }

        tickets[index].isUsed = true
        tickets[index].usedAt = usedAt
        return true
    }
}
