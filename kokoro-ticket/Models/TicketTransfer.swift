import Foundation

/// 送信者・受取人と送信日時のスナップショットを保持する転送情報
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
