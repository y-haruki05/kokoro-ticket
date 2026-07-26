import Foundation

enum AppError: Error, LocalizedError, Equatable {
    case missingConfiguration(key: String)
    case invalidConfiguration(key: String, reason: String)
    case emailRequired
    case passwordRequired
    case passwordMismatch
    case authentication(description: String)
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
        case .passwordRequired:
            "パスワードを入力してください"
        case .passwordMismatch:
            "パスワードが一致しません"
        case let .authentication(description):
            description
        case let .network(description):
            "通信に失敗しました: \(description)"
        case let .repository(description):
            "データ処理に失敗しました: \(description)"
        }
    }
}
