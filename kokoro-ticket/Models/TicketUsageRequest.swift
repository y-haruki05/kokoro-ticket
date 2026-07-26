import Foundation

struct TicketUsageRequest: Identifiable, Hashable, Sendable {
    let id: UUID
    let ticketID: UUID
    let requesterID: UUID
    let requestedAt: Date
    let completedBy: UUID?
    let completedAt: Date?
}
