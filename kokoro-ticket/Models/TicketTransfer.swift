import Foundation

struct TicketTransfer: Identifiable, Hashable, Sendable {
    let id: UUID
    let ticketID: UUID
    let senderID: UUID
    let receiverID: UUID
    let senderNameSnapshot: String
    let receiverNameSnapshot: String
    let sentAt: Date
    let receivedAt: Date?
}
