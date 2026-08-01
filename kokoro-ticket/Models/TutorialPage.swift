import Foundation

enum TutorialPresentationMode: Equatable, Sendable {
    case firstLaunch
    case manual

    var dismissTitle: String {
        switch self {
        case .firstLaunch: "スキップ"
        case .manual: "閉じる"
        }
    }

    var completionTitle: String {
        switch self {
        case .firstLaunch: "はじめる"
        case .manual: "アプリに戻る"
        }
    }
}

enum TutorialPage: Int, CaseIterable, Identifiable, Sendable {
    case welcome
    case createTicket
    case sendToFriend
    case requestUsage
    case memories

    var id: Int { rawValue }

    var pageNumber: Int { rawValue + 1 }

    var title: String {
        switch self {
        case .welcome: "ようこそ、こころチケットへ！"
        case .createTicket: "オリジナルのチケットを作ろう"
        case .sendToFriend: "大切な人へ贈ろう"
        case .requestUsage: "使いたい時にリクエスト"
        case .memories: "使ったチケットは思い出に"
        }
    }

    var message: String {
        switch self {
        case .welcome:
            """
            大切な人へ、
            気持ちをチケットにして届けるアプリです。
            """
        case .createTicket:
            """
            「肩たたき券」や「一緒におでかけ券」など、相手にしてあげたいことを自由にチケットにできます。

            ここにゃんや色、枠を選んで、世界に1枚だけのチケットを作りましょう。
            """
        case .sendToFriend:
            """
            フレンドコードで大切な人とつながると、作ったチケットを贈ることができます。

            言葉だけでは伝えにくい気持ちも、チケットなら自然に届けられます。
            """
        case .requestUsage:
            """
            受け取ったチケットは、使いたいタイミングで相手へリクエストできます。

            相手が完了すると、チケットは大切な思い出になります。
            """
        case .memories:
            """
            完了したチケットは、思い出のアルバムへ残ります。

            大切な人と過ごした時間を、いつでも振り返ることができます。
            """
        }
    }
}
