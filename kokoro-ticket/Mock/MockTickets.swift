enum MockTickets {
    static let today = Ticket(
        title: "おつかれさま券",
        message: "頑張った日に使ってね。好きなお菓子と飲み物を用意します！",
        senderName: "かぞく"
    )

    static let received = [
        Ticket(
            title: "ぎゅー券",
            message: "寂しい時や元気が欲しい時に使ってね。ぎゅっと抱きしめます！",
            senderName: "ママ"
        ),
        Ticket(
            title: "だいすき券",
            message: "使ってくれたら、あなたの好きなところを10個伝えます！",
            senderName: "パパ"
        ),
        Ticket(
            title: "おてつだい券",
            message: "忙しい日に使ってね。お部屋のお片づけを手伝います！",
            senderName: "かぞく"
        )
    ]
}
