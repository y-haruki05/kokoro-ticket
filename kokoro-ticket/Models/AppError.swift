import Foundation

enum AppError: Error, LocalizedError, Equatable {
    case missingConfiguration(key: String)
    case invalidConfiguration(key: String, reason: String)
    case emailRequired
    case invalidEmail
    case passwordRequired
    case passwordTooShort(minimumLength: Int)
    case passwordMismatch
    case emailAlreadyRegistered
    case signupRateLimited
    case confirmationEmailFailed
    case signupUnavailable
    case captchaFailed
    case authentication(description: String)
    case authenticatedUserUnavailable
    case invalidDisplayName
    case profileNotFound
    case profile(description: String)
    case friendCodeGenerationFailed
    case friendCodeDuplicated
    case invalidFriendCode
    case friendNotFound
    case friendRequestToSelf
    case alreadyFriends
    case friendRequestAlreadySent
    case incomingFriendRequestExists
    case friendRequestAlreadyProcessed
    case friendPermissionDenied
    case friend(description: String)
    case ticketNotDraft
    case ticketNotOwned
    case ticketReceiverNotFriend
    case ticketSendToSelf
    case ticketAlreadySent
    case ticketPermissionDenied
    case ticketTransfer(description: String)
    case ticketReceiverOnly
    case ticketNotSent
    case ticketNotReceived
    case ticketUsageAlreadyRequested
    case ticketAcknowledgementFailed
    case ticketUsageRequestFailed
    case network(description: String)
    case repository(description: String)

    var errorDescription: String? {
        switch self {
        case let .missingConfiguration(key):
            "設定値「\(key)」が見つかりません"
        case let .invalidConfiguration(key, reason):
            "設定値「\(key)」が不正です: \(reason)"
        case .emailRequired:
            "メールアドレスを入力してください"
        case .invalidEmail:
            "正しいメールアドレスを入力してください"
        case .passwordRequired:
            "パスワードを入力してください"
        case let .passwordTooShort(minimumLength):
            "パスワードは\(minimumLength)文字以上で入力してください"
        case .passwordMismatch:
            "パスワードが一致しません"
        case .emailAlreadyRegistered:
            "このメールアドレスはすでに登録されています"
        case .signupRateLimited:
            "短時間に登録を繰り返したため、しばらく待ってからもう一度お試しください"
        case .confirmationEmailFailed:
            "確認メールを送信できませんでした。しばらく待ってからもう一度お試しください"
        case .signupUnavailable:
            "現在、新規登録を利用できません"
        case .captchaFailed:
            "認証確認に失敗しました。もう一度お試しください"
        case let .authentication(description):
            description
        case .authenticatedUserUnavailable:
            "ログインユーザーを確認できませんでした"
        case .invalidDisplayName:
            "表示名は1〜30文字で入力してください"
        case .profileNotFound:
            "プロフィールが見つかりません"
        case let .profile(description):
            description
        case .friendCodeGenerationFailed:
            "フレンドコードを発行できませんでした。もう一度お試しください"
        case .friendCodeDuplicated:
            "フレンドコードが重複しました。もう一度お試しください"
        case .invalidFriendCode:
            "8文字の正しいフレンドコードを入力してください"
        case .friendNotFound:
            "フレンドコードに一致するユーザーが見つかりません"
        case .friendRequestToSelf:
            "自分自身へフレンド申請はできません"
        case .alreadyFriends:
            "すでにフレンドです"
        case .friendRequestAlreadySent:
            "このユーザーへは申請済みです"
        case .incomingFriendRequestExists:
            "相手からフレンド申請が届いています"
        case .friendRequestAlreadyProcessed:
            "この申請はすでに処理されています"
        case .friendPermissionDenied:
            "この操作を行う権限がありません"
        case let .friend(description):
            description
        case .ticketNotDraft:
            "作り置き状態のチケットだけ送信できます"
        case .ticketNotOwned:
            "自分のチケットだけ送信できます"
        case .ticketReceiverNotFriend:
            "フレンド以外にはチケットを送信できません"
        case .ticketSendToSelf:
            "自分自身へチケットは送信できません"
        case .ticketAlreadySent:
            "このチケットはすでに送信されています"
        case .ticketPermissionDenied:
            "このチケットを操作する権限がありません"
        case let .ticketTransfer(description):
            description
        case .ticketReceiverOnly:
            "チケットの受取人だけが操作できます"
        case .ticketNotSent:
            "送信済みのチケットだけ受け取れます"
        case .ticketNotReceived:
            "受取確認済みのチケットだけ使用をリクエストできます"
        case .ticketUsageAlreadyRequested:
            "このチケットはすでに使用リクエスト済みです"
        case .ticketAcknowledgementFailed:
            "チケットを受け取れませんでした"
        case .ticketUsageRequestFailed:
            "使用リクエストを送信できませんでした"
        case .network:
            "ネットワーク接続を確認してください"
        case let .repository(description):
            "データ処理に失敗しました: \(description)"
        }
    }
}
