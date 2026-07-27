import Foundation
import UserNotifications

enum PushAuthorizationStatus: Sendable {
    case notDetermined, authorized, denied
}

enum DeviceTokenRegistrationState: Sendable {
    case idle, registering, registered, failed
}

struct PushNotificationPayload: Sendable, Equatable {
    let notificationID: UUID
    let type: AppNotificationType
    let resourceType: NotificationResourceType
    let resourceID: UUID

    init(userInfo: [AnyHashable: Any]) throws {
        guard
            let notificationID = UUID(uuidString: userInfo["notification_id"] as? String ?? ""),
            let type = AppNotificationType(rawValue: userInfo["type"] as? String ?? ""),
            let resourceType = NotificationResourceType(
                rawValue: userInfo["resource_type"] as? String ?? ""
            ),
            let resourceID = UUID(uuidString: userInfo["resource_id"] as? String ?? "")
        else {
            throw AppError.pushPayloadInvalid
        }
        self.notificationID = notificationID
        self.type = type
        self.resourceType = resourceType
        self.resourceID = resourceID
    }

    var notification: AppNotification {
        AppNotification(
            id: notificationID,
            recipientID: UUID(),
            actorID: nil,
            actorDisplayName: nil,
            actorAvatarKey: nil,
            type: type,
            resourceType: resourceType,
            resourceID: resourceID,
            title: "",
            message: "",
            payload: [:],
            readAt: nil,
            createdAt: .now
        )
    }
}
