import Foundation

/// 受取人からの使用依頼と、送り主による完了情報を表す
struct TicketUsageRequest: Identifiable, Hashable, Sendable {
    let id: UUID
    let ticketID: UUID
    let requesterID: UUID
    let requestedAt: Date
    let completedBy: UUID?
    let completedAt: Date?
}
