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
            title: "こころチケット \(index + 1)",
            message: "いつもありがとう",
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
