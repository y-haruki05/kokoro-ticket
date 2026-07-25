import Foundation

enum MockTicketListItems {
    static let items = [
        makeTicket(
            id: "00000000-0000-0000-0000-000000000001",
            title: "おてつだい券",
            message: "今日はぼくにまかせてね",
            receiverName: nil,
            status: .draft,
            daysAgo: 0
        ),
        makeTicket(
            id: "00000000-0000-0000-0000-000000000002",
            title: "だいすき券",
            message: "いつもありがとう",
            receiverName: "おかあさん",
            status: .sent,
            daysAgo: 1
        ),
        makeTicket(
            id: "00000000-0000-0000-0000-000000000003",
            title: "肩たたき券",
            message: "ゆっくり休んでね",
            receiverName: "おとうさん",
            status: .received,
            daysAgo: 2
        ),
        makeTicket(
            id: "00000000-0000-0000-0000-000000000004",
            title: "ぎゅー券",
            message: "だいすきの気持ちをこめて",
            receiverName: "おかあさん",
            status: .requested,
            daysAgo: 4
        ),
        makeTicket(
            id: "00000000-0000-0000-0000-000000000005",
            title: "おつかれさま券",
            message: "いつもありがとう！",
            receiverName: "おかあさん",
            status: .completed,
            daysAgo: 8
        )
    ]

    private static func makeTicket(
        id: String,
        title: String,
        message: String,
        receiverName: String?,
        status: TicketStatus,
        daysAgo: Int
    ) -> TicketListItem {
        let createdAt = date(daysAgo: daysAgo)
        let transitionAt = date(daysAgo: max(daysAgo - 1, 0))

        return TicketListItem(
            id: UUID(uuidString: id) ?? UUID(),
            illustration: TicketIllustration(id: id),
            title: title,
            message: message,
            senderName: "ゆうせい",
            receiverName: receiverName,
            createdAt: createdAt,
            updatedAt: transitionAt,
            sentAt: status == .draft ? nil : transitionAt,
            receivedAt: [.received, .requested, .completed].contains(status) ? transitionAt : nil,
            requestedAt: [.requested, .completed].contains(status) ? transitionAt : nil,
            completedAt: status == .completed ? transitionAt : nil,
            status: status,
            design: TicketDesign(
                backgroundColor: .lightBlue,
                borderStyle: .roundedBold
            )
        )
    }

    private static func date(daysAgo: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: -daysAgo, to: .now) ?? .now
    }
}
