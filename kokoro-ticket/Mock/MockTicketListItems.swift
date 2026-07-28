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

    static let senderItems = items.map { item in
        item.viewed(as: item.status == .draft ? .local : .sender)
    }

    static let receiverItems = [
        copy(
            items[1],
            id: "10000000-0000-0000-0000-000000000002",
            perspective: .receiver
        ),
        copy(
            items[2],
            id: "10000000-0000-0000-0000-000000000003",
            perspective: .receiver
        ),
        copy(
            items[3],
            id: "10000000-0000-0000-0000-000000000004",
            perspective: .receiver
        ),
        copy(
            items[4],
            id: "10000000-0000-0000-0000-000000000005",
            perspective: .receiver
        )
    ]

    static let allPerspectives = [
        senderItems[0],
        senderItems[1],
        receiverItems[0],
        receiverItems[1],
        senderItems[3],
        receiverItems[2],
        receiverItems[3]
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

    private static func copy(
        _ item: TicketListItem,
        id: String,
        perspective: TicketPerspective
    ) -> TicketListItem {
        TicketListItem(
            id: UUID(uuidString: id) ?? UUID(),
            illustration: item.illustration,
            title: item.title,
            message: item.message,
            senderName: item.senderName,
            receiverName: item.receiverName,
            createdAt: item.createdAt,
            updatedAt: item.updatedAt,
            sentAt: item.sentAt,
            receivedAt: item.receivedAt,
            requestedAt: item.requestedAt,
            completedAt: item.completedAt,
            status: item.status,
            perspective: perspective,
            design: item.design
        )
    }
}
