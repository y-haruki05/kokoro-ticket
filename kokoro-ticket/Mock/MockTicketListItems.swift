import Foundation

enum MockTicketListItems {
    static let items = [
        makeTicket(
            id: "00000000-0000-0000-0000-000000000001",
            title: "おてつだい券",
            message: "忙しい日に使ってね。お部屋のお片づけを手伝います！",
            receiverName: nil,
            status: .draft,
            daysAgo: 0
        ),
        makeTicket(
            id: "00000000-0000-0000-0000-000000000002",
            title: "だいすき券",
            message: "使ってくれたら、あなたの好きなところを10個伝えます！",
            receiverName: "おかあさん",
            status: .sent,
            daysAgo: 1
        ),
        makeTicket(
            id: "00000000-0000-0000-0000-000000000003",
            title: "肩たたき券",
            message: "疲れた時に使ってね。心を込めて肩をたたきます！",
            receiverName: "おとうさん",
            status: .received,
            daysAgo: 2
        ),
        makeTicket(
            id: "00000000-0000-0000-0000-000000000004",
            title: "ぎゅー券",
            message: "寂しい時や元気が欲しい時に使ってね。ぎゅっと抱きしめます！",
            receiverName: "おかあさん",
            status: .requested,
            daysAgo: 4
        ),
        makeTicket(
            id: "00000000-0000-0000-0000-000000000005",
            title: "おつかれさま券",
            message: "頑張った日に使ってね。好きなお菓子と飲み物を用意します！",
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
