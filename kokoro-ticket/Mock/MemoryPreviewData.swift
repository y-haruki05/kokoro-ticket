import Foundation

#if DEBUG
enum MemoryPreviewData {
    static let single = make(
        id: "62000000-0000-0000-0000-000000000001",
        title: "肩たたき券",
        message: "疲れた日に使ってね。心を込めて肩をたたきます！",
        monthOffset: 0,
        dayOffset: -2,
        illustration: "cat_happy"
    )

    static let longText = make(
        id: "62000000-0000-0000-0000-000000000002",
        title: "一緒にゆっくりおでかけする券",
        message: "忙しい毎日の中でも、好きな場所を一緒に歩いて、おいしいものを食べながらゆっくりお話しするためのチケットです。",
        monthOffset: 0,
        dayOffset: -5,
        illustration: "cat_ticket"
    )

    static let multipleMonths = [
        single,
        longText,
        make(
            id: "62000000-0000-0000-0000-000000000003",
            title: "ぎゅー券",
            message: "元気が欲しい時に使ってね。ぎゅっと抱きしめます！",
            monthOffset: -1,
            dayOffset: -3,
            illustration: "cat_default"
        ),
        make(
            id: "62000000-0000-0000-0000-000000000004",
            title: "おやつ券",
            message: "好きなお菓子と飲み物を用意します！",
            monthOffset: -2,
            dayOffset: -7,
            illustration: "cat_welcome"
        )
    ]

    private static func make(
        id: String,
        title: String,
        message: String,
        monthOffset: Int,
        dayOffset: Int,
        illustration: String
    ) -> TicketListItem {
        let calendar = Calendar(identifier: .gregorian)
        let month = calendar.date(byAdding: .month, value: monthOffset, to: .now) ?? .now
        let completedAt = calendar.date(byAdding: .day, value: dayOffset, to: month) ?? month
        let sentAt = calendar.date(byAdding: .day, value: -4, to: completedAt) ?? completedAt
        let receivedAt = calendar.date(byAdding: .day, value: 1, to: sentAt) ?? sentAt
        let requestedAt = calendar.date(byAdding: .day, value: 1, to: receivedAt) ?? receivedAt

        return TicketListItem(
            id: UUID(uuidString: id) ?? UUID(),
            illustration: TicketIllustration(id: illustration),
            title: title,
            message: message,
            senderName: "ゆうせい",
            receiverName: "こころ",
            createdAt: sentAt,
            updatedAt: completedAt,
            sentAt: sentAt,
            receivedAt: receivedAt,
            requestedAt: requestedAt,
            completedAt: completedAt,
            status: .completed,
            perspective: .receiver,
            design: TicketDesign(
                backgroundColor: monthOffset.isMultiple(of: 2) ? .lightBlue : .lightPink,
                borderStyle: .roundedBold
            )
        )
    }
}
#endif
