import SwiftUI

@MainActor
enum HomePreviewFactory {
    static func make(
        tickets: [TicketListItem] = HomePreviewData.normalTickets,
        notifications: [AppNotification] = NotificationPreviewData.allTypes,
        presentation: HomePreviewPresentation = .automatic
    ) -> some View {
        let ticketStore = TicketStore(previewTickets: tickets)
        let notificationStore = NotificationStore(
            repository: InMemoryNotificationRepository(notifications: notifications),
            notifications: notifications,
            unreadCount: notifications.filter { !$0.isRead }.count
        )

        return NavigationStack {
            HomeView(
                ticketStore: ticketStore,
                notificationStore: notificationStore,
                displayName: "山本",
                presentation: presentation
            )
        }
    }
}

enum HomePreviewData {
    static let normalTickets = [
        previewTicket(index: 0, status: .sent),
        previewTicket(index: 1, status: .received),
        previewTicket(index: 2, status: .completed),
        previewTicket(index: 4, status: .completed)
    ]

    static let manyTickets: [TicketListItem] = (0..<6).map { index in
        previewTicket(index: index, status: index == 0 ? .sent : .received)
    }

    static let manyMemories: [TicketListItem] = (0..<7).map { index in
        previewTicket(index: index, status: .completed)
    }

    private static func previewTicket(index: Int, status: TicketStatus) -> TicketListItem {
        let date = Calendar.current.date(byAdding: .day, value: -index, to: .now) ?? .now
        return TicketListItem(
            illustration: nil,
            title: ["肩たたき券", "ぎゅー券", "だいすき券"][index % 3],
            message: [
                "疲れた時に使ってね。心を込めて肩をたたきます！",
                "寂しい時や元気が欲しい時に使ってね。ぎゅっと抱きしめます！",
                "使ってくれたら、あなたの好きなところを10個伝えます！"
            ][index % 3],
            senderName: "フレンド\(index + 1)",
            receiverName: "山本",
            createdAt: date,
            sentAt: date,
            receivedAt: status == .sent ? nil : date,
            requestedAt: status == .completed ? date : nil,
            completedAt: status == .completed ? date : nil,
            status: status,
            perspective: .receiver,
            design: TicketDesign(backgroundColor: .lightBlue, borderStyle: .roundedBold)
        )
    }
}
