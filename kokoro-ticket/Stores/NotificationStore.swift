import Foundation
import Observation

@MainActor
@Observable
final class NotificationStore {
    private(set) var notifications: [AppNotification]
    private(set) var unreadCount: Int
    private(set) var isLoading = false
    private(set) var isLoadingMore = false
    private(set) var isMarkingAllRead = false
    private(set) var hasMore = true
    private(set) var error: AppError?
    private(set) var readError: AppError?

    @ObservationIgnored private let repository: any NotificationRepository
    @ObservationIgnored private let pageSize = 20
    @ObservationIgnored private var readingIDs = Set<UUID>()

    init(
        repository: any NotificationRepository,
        notifications: [AppNotification] = [],
        unreadCount: Int = 0
    ) {
        self.repository = repository
        self.notifications = notifications
        self.unreadCount = unreadCount
    }

    func reload() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            async let page = repository.fetchNotifications(offset: 0, limit: pageSize)
            async let count = repository.fetchUnreadCount()
            let result = try await (page, count)
            notifications = unique(result.0.notifications)
            hasMore = result.0.hasMore
            unreadCount = result.1
            error = nil
        } catch {
            self.error = normalize(error, fallback: .notificationFetchFailed)
        }
    }

    func loadMoreIfNeeded(current notification: AppNotification) async {
        guard hasMore, !isLoadingMore, notification.id == notifications.last?.id else { return }
        isLoadingMore = true
        defer { isLoadingMore = false }
        do {
            let page = try await repository.fetchNotifications(
                offset: notifications.count,
                limit: pageSize
            )
            notifications = unique(notifications + page.notifications)
            hasMore = page.hasMore
        } catch {
            self.error = normalize(error, fallback: .notificationPageFailed)
        }
    }

    func markAsRead(_ notification: AppNotification) async {
        guard !notification.isRead, readingIDs.insert(notification.id).inserted else { return }
        defer { readingIDs.remove(notification.id) }
        do {
            let date = try await repository.markAsRead(id: notification.id)
            if let index = notifications.firstIndex(where: { $0.id == notification.id }) {
                notifications[index].readAt = date
            }
            unreadCount = max(0, unreadCount - 1)
            readError = nil
        } catch {
            readError = normalize(error, fallback: .notificationReadFailed)
        }
    }

    func markAllAsRead() async {
        guard unreadCount > 0, !isMarkingAllRead else { return }
        isMarkingAllRead = true
        defer { isMarkingAllRead = false }
        do {
            let date = try await repository.markAllAsRead()
            for index in notifications.indices where !notifications[index].isRead {
                notifications[index].readAt = date
            }
            unreadCount = 0
            readError = nil
        } catch {
            readError = normalize(error, fallback: .notificationReadFailed)
        }
    }

    @discardableResult
    func reloadFromRealtime() async -> Bool {
        while isLoading {
            do {
                try await Task.sleep(for: .milliseconds(100))
            } catch {
                return false
            }
        }
        await reload()
        return error == nil
    }

    func clearError() {
        error = nil
        readError = nil
    }

    private func unique(_ values: [AppNotification]) -> [AppNotification] {
        var seen = Set<UUID>()
        return values
            .sorted { $0.createdAt > $1.createdAt }
            .filter { seen.insert($0.id).inserted }
    }

    private func normalize(_ error: Error, fallback: AppError) -> AppError {
        if let appError = error as? AppError { return appError }
        if let urlError = error as? URLError {
            return .network(description: urlError.localizedDescription)
        }
        return fallback
    }
}
