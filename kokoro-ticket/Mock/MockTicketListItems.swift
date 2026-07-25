import Foundation

enum MockTicketListItems {
    static let items = [
        TicketListItem(
            illustration: TicketIllustration(id: "received-01"),
            title: "おつかれさま券",
            message: "いつもありがとう！",
            counterpartName: "ママ",
            counterpartLabel: "差出人",
            createdAt: daysAgo(0),
            status: .unused,
            category: .received
        ),
        TicketListItem(
            illustration: TicketIllustration(id: "received-02"),
            title: "肩たたき券",
            message: "ゆっくり休んでね",
            counterpartName: "おとうさん",
            counterpartLabel: "差出人",
            createdAt: daysAgo(2),
            status: .unused,
            category: .received
        ),
        TicketListItem(
            illustration: TicketIllustration(id: "received-03"),
            title: "ぎゅー券",
            message: "だいすきの気持ちをこめて",
            counterpartName: "いもうと",
            counterpartLabel: "差出人",
            createdAt: daysAgo(5),
            status: .unused,
            category: .received
        ),
        TicketListItem(
            illustration: TicketIllustration(id: "sent-01"),
            title: "おてつだい券",
            message: "今日はぼくにまかせてね",
            counterpartName: "おかあさん",
            counterpartLabel: "宛先",
            createdAt: daysAgo(1),
            status: .unused,
            category: .sent
        ),
        TicketListItem(
            illustration: TicketIllustration(id: "sent-02"),
            title: "だいすき券",
            message: "いつもありがとう",
            counterpartName: "おとうさん",
            counterpartLabel: "宛先",
            createdAt: daysAgo(7),
            status: .unused,
            category: .sent
        ),
        TicketListItem(
            illustration: TicketIllustration(id: "used-01"),
            title: "だいすき券",
            message: "いっしょに遊ぼう",
            counterpartName: "ママ",
            counterpartLabel: "差出人",
            createdAt: daysAgo(10),
            status: .used,
            category: .used
        )
    ]

    private static func daysAgo(_ days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: -days, to: .now) ?? .now
    }
}
