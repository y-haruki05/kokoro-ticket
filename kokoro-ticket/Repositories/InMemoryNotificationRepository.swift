import Foundation

@MainActor
final class InMemoryNotificationRepository: NotificationRepository {
    private var values: [AppNotification]
    var error: AppError?

    init(notifications: [AppNotification] = [], error: AppError? = nil) {
        values = notifications.sorted { $0.createdAt > $1.createdAt }
        self.error = error
    }

    func fetchNotifications(offset: Int, limit: Int) async throws -> NotificationPage {
        if let error { throw error }
        let slice = Array(values.dropFirst(offset).prefix(limit))
        return NotificationPage(
            notifications: slice,
            hasMore: offset + slice.count < values.count
        )
    }

    func fetchUnreadCount() async throws -> Int {
        if let error { throw error }
        return values.filter { !$0.isRead }.count
    }

    func markAsRead(id: UUID) async throws -> Date {
        if let error { throw error }
        guard let index = values.firstIndex(where: { $0.id == id }) else {
            throw AppError.notificationTargetUnavailable
        }
        let date = values[index].readAt ?? .now
        values[index].readAt = date
        return date
    }

    func markAllAsRead() async throws -> Date {
        if let error { throw error }
        let date = Date.now
        for index in values.indices where !values[index].isRead {
            values[index].readAt = date
        }
        return date
    }
}
