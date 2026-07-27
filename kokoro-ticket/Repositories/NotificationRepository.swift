import Foundation

@MainActor
protocol NotificationRepository {
    func fetchNotifications(offset: Int, limit: Int) async throws -> NotificationPage
    func fetchUnreadCount() async throws -> Int
    func markAsRead(id: UUID) async throws -> Date
    func markAllAsRead() async throws -> Date
}
