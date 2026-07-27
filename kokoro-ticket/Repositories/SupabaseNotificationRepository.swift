import Foundation
import OSLog
import Supabase

@MainActor
final class SupabaseNotificationRepository: NotificationRepository {
    private let client: Supabase.SupabaseClient
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "kokoro-ticket",
        category: "NotificationRepository"
    )

    init(clientProvider: any SupabaseClientProviding) {
        client = clientProvider.client
    }

    func fetchNotifications(offset: Int, limit: Int) async throws -> NotificationPage {
        do {
            let records: [NotificationRecord] = try await client
                .rpc(
                    "get_notifications",
                    params: ["page_offset": offset, "page_limit": limit]
                )
                .execute()
                .value
            return NotificationPage(
                notifications: records.map(\.model),
                hasMore: records.count == limit
            )
        } catch {
            throw map(error, fallback: .notificationFetchFailed)
        }
    }

    func fetchUnreadCount() async throws -> Int {
        do {
            return try await client
                .rpc("get_unread_notification_count")
                .execute()
                .value
        } catch {
            throw map(error, fallback: .notificationUnreadCountFailed)
        }
    }

    func markAsRead(id: UUID) async throws -> Date {
        do {
            return try await client
                .rpc(
                    "mark_notification_as_read",
                    params: ["target_notification_id": id.uuidString]
                )
                .execute()
                .value
        } catch {
            throw map(error, fallback: .notificationReadFailed)
        }
    }

    func markAllAsRead() async throws -> Date {
        do {
            return try await client
                .rpc("mark_all_notifications_as_read")
                .execute()
                .value
        } catch {
            throw map(error, fallback: .notificationReadFailed)
        }
    }

    private func map(_ error: Error, fallback: AppError) -> AppError {
        if let appError = error as? AppError { return appError }
        let description = String(reflecting: error).lowercased()
        logger.error("Notification operation failed: \(String(describing: type(of: error)), privacy: .public)")
        if description.contains("42501") || description.contains("permission") {
            return .notificationPermissionDenied
        }
        if error is URLError { return .network(description: "通知通信エラー") }
        return fallback
    }
}

private struct NotificationRecord: Decodable {
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
    let payload: [String: String]?
    let readAt: Date?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, type, title, message, payload
        case recipientID = "recipient_id"
        case actorID = "actor_id"
        case actorDisplayName = "actor_display_name"
        case actorAvatarKey = "actor_avatar_key"
        case resourceType = "resource_type"
        case resourceID = "resource_id"
        case readAt = "read_at"
        case createdAt = "created_at"
    }

    var model: AppNotification {
        AppNotification(
            id: id,
            recipientID: recipientID,
            actorID: actorID,
            actorDisplayName: actorDisplayName,
            actorAvatarKey: actorAvatarKey,
            type: type,
            resourceType: resourceType,
            resourceID: resourceID,
            title: title,
            message: message,
            payload: payload ?? [:],
            readAt: readAt,
            createdAt: createdAt
        )
    }
}
