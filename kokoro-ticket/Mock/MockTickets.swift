enum MockTickets {
    static let today = Ticket(
        title: "おつかれさま券",
        message: "いつもありがとう！",
        senderName: "かぞく"
    )

    static let received = [
        Ticket(
            title: "ぎゅー券",
            message: "だいすきの気持ちをこめて",
            senderName: "ママ"
        ),
        Ticket(
            title: "だいすき券",
            message: "いつもいっしょにいてくれてありがとう",
            senderName: "パパ"
        ),
        Ticket(
            title: "おてつだい券",
            message: "今日はぼくにまかせてね",
            senderName: "かぞく"
        )
    ]
}
