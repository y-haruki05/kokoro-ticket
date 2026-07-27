import Foundation

enum NotificationPreviewData {
    static let userID = UUID()

    static let allTypes: [AppNotification] = AppNotificationType.allCases.enumerated().map {
        index, type in
        AppNotification(
            id: UUID(),
            recipientID: userID,
            actorID: UUID(),
            actorDisplayName: index.isMultiple(of: 2) ? "こころさん" : "はるさん",
            actorAvatarKey: nil,
            type: type,
            resourceType: type == .friendRequestReceived ? .friendRequest :
                (type == .friendRequestAccepted ? .friendship : .ticket),
            resourceID: UUID(),
            title: title(for: type),
            message: message(for: type),
            payload: [:],
            readAt: index > 2 ? .now : nil,
            createdAt: .now.addingTimeInterval(Double(-index * 600))
        )
    }

    static let many: [AppNotification] = (0..<25).map { index in
        let value = allTypes[index % allTypes.count]
        return AppNotification(
            id: UUID(),
            recipientID: value.recipientID,
            actorID: value.actorID,
            actorDisplayName: value.actorDisplayName,
            actorAvatarKey: nil,
            type: value.type,
            resourceType: value.resourceType,
            resourceID: UUID(),
            title: value.title,
            message: value.message,
            payload: [:],
            readAt: index.isMultiple(of: 3) ? .now : nil,
            createdAt: .now.addingTimeInterval(Double(-index * 60))
        )
    }

    private static func title(for type: AppNotificationType) -> String {
        switch type {
        case .friendRequestReceived: "フレンド申請が届きました"
        case .friendRequestAccepted: "フレンドになりました"
        case .ticketReceived: "チケットが届きました"
        case .ticketAcknowledged: "チケットが受け取られました"
        case .ticketUsageRequested: "使用リクエストが届きました"
        case .ticketCompleted: "チケットが完了しました"
        }
    }

    private static func message(for type: AppNotificationType) -> String {
        switch type {
        case .friendRequestReceived: "フレンド申請を確認してください"
        case .friendRequestAccepted: "フレンド一覧から確認できます"
        case .ticketReceived: "受け取ったチケットを確認しましょう"
        case .ticketAcknowledged: "送ったチケットが受け取られました"
        case .ticketUsageRequested: "チケットの内容を実行したら完了にしてください"
        case .ticketCompleted: "思い出に新しいチケットが追加されました"
        }
    }
}
