import Foundation

/// 通知一覧・未読件数・既読処理を提供するRepositoryの契約
@MainActor
protocol NotificationRepository {
    func fetchNotifications(offset: Int, limit: Int) async throws -> NotificationPage
    func fetchUnreadCount() async throws -> Int
    func markAsRead(id: UUID) async throws -> Date
    func markAllAsRead() async throws -> Date
}
