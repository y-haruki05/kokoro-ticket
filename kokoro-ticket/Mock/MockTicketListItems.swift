import Foundation

enum MockTicketListItems {
    static let items = [
        TicketListItem(
            illustration: TicketIllustration(id: "received-01"),
            title: "おつかれさま券",
            message: "いつもありがとう！",
            senderName: "ママ",
            receiverName: "ゆうせい",
            counterpartName: "ママ",
            counterpartLabel: "差出人",
            createdAt: daysAgo(0),
            status: .unused,
            category: .received,
            design: TicketDesign(backgroundColor: .lightBlue, borderStyle: .simple)
        ),
        TicketListItem(
            illustration: TicketIllustration(id: "received-02"),
            title: "肩たたき券",
            message: "ゆっくり休んでね",
            senderName: "おとうさん",
            receiverName: "ゆうせい",
            counterpartName: "おとうさん",
            counterpartLabel: "差出人",
            createdAt: daysAgo(2),
            status: .unused,
            category: .received,
            design: TicketDesign(backgroundColor: .white, borderStyle: .dashed)
        ),
        TicketListItem(
            illustration: TicketIllustration(id: "received-03"),
            title: "ぎゅー券",
            message: "だいすきの気持ちをこめて",
            senderName: "いもうと",
            receiverName: "ゆうせい",
            counterpartName: "いもうと",
            counterpartLabel: "差出人",
            createdAt: daysAgo(5),
            status: .unused,
            category: .received,
            design: TicketDesign(backgroundColor: .lightPink, borderStyle: .roundedBold)
        ),
        TicketListItem(
            illustration: TicketIllustration(id: "sent-01"),
            title: "おてつだい券",
            message: "今日はぼくにまかせてね",
            senderName: "ゆうせい",
            receiverName: "おかあさん",
            counterpartName: "おかあさん",
            counterpartLabel: "宛先",
            createdAt: daysAgo(1),
            status: .unused,
            category: .sent,
            design: TicketDesign(backgroundColor: .lightYellow, borderStyle: .double)
        ),
        TicketListItem(
            illustration: TicketIllustration(id: "sent-02"),
            title: "だいすき券",
            message: "いつもありがとう",
            senderName: "ゆうせい",
            receiverName: "おとうさん",
            counterpartName: "おとうさん",
            counterpartLabel: "宛先",
            createdAt: daysAgo(7),
            status: .unused,
            category: .sent,
            design: TicketDesign(backgroundColor: .lightBlue, borderStyle: .dashed)
        ),
        TicketListItem(
            illustration: TicketIllustration(id: "used-01"),
            title: "だいすき券",
            message: "いっしょに遊ぼう",
            senderName: "ママ",
            receiverName: "ゆうせい",
            counterpartName: "ママ",
            counterpartLabel: "差出人",
            createdAt: daysAgo(10),
            status: .used,
            category: .used,
            design: TicketDesign(backgroundColor: .lightPink, borderStyle: .simple)
        )
    ]

    private static func daysAgo(_ days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: -days, to: .now) ?? .now
    }
}
