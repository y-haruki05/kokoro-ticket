import Foundation

/// 通知種別とresource情報を、対応するアプリ内遷移へ変換する
enum AppDeepLinkMapper {
    static func map(_ notification: AppNotification) throws -> AppDeepLink {
        switch (notification.type, notification.resourceType) {
        case (.friendRequestReceived, .friendRequest):
            return .incomingFriendRequest(notification.resourceID)
        case (.friendRequestAccepted, .friendship):
            guard let friendID = notification.actorID else {
                throw AppError.deepLinkInvalidResource
            }
            return .friend(friendID)
        case (.ticketReceived, .ticket):
            return .receivedTicket(notification.resourceID)
        case (.ticketAcknowledged, .ticket):
            return .sentTicket(notification.resourceID)
        case (.ticketUsageRequested, .ticket):
            return .waitingTicket(notification.resourceID)
        case (.ticketCompleted, .ticket):
            return .completedTicket(notification.resourceID)
        default:
            throw AppError.deepLinkInvalidResource
        }
    }
}
