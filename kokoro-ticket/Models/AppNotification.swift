import Foundation

/// フレンドとチケットの状態変化から生成される通知種別
enum AppNotificationType: String, Codable, Sendable, CaseIterable {
    case friendRequestReceived = "friend_request_received"
    case friendRequestAccepted = "friend_request_accepted"
    case ticketReceived = "ticket_received"
    case ticketAcknowledged = "ticket_acknowledged"
    case ticketUsageRequested = "ticket_usage_requested"
    case ticketCompleted = "ticket_completed"

    var iconName: String {
        switch self {
        case .friendRequestReceived: "person.badge.plus"
        case .friendRequestAccepted: "person.2.fill"
        case .ticketReceived: "ticket.fill"
        case .ticketAcknowledged: "checkmark.circle"
        case .ticketUsageRequested: "hand.raised.fill"
        case .ticketCompleted: "heart.fill"
        }
    }
}

enum NotificationResourceType: String, Codable, Sendable {
    case friendRequest = "friend_request"
    case friendship
    case ticket
}

struct AppNotification: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    let recipientID: UUID
    let actorID: UUID?
    let actorDisplayName: String?
    let actorAvatarKey: String?
    let type: AppNotificationType
    let resourceType: NotificationResourceType
    let resourceID: UUID
    let title: String
    let message: String
    let payload: [String: String]
    var readAt: Date?
    let createdAt: Date

    var isRead: Bool { readAt != nil }
}

struct NotificationPage: Sendable {
    let notifications: [AppNotification]
    let hasMore: Bool
}
