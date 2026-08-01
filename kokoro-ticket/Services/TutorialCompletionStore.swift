import Foundation

/// 初回チュートリアルの完了状態を永続化するためのインターフェース
protocol TutorialCompletionStoring: AnyObject {
    var hasCompletedTutorial: Bool { get set }
}

final class UserDefaultsTutorialCompletionStore: TutorialCompletionStoring {
    private let defaults: UserDefaults
    private let key: String

    init(
        defaults: UserDefaults = .standard,
        key: String = "hasCompletedTutorial"
    ) {
        self.defaults = defaults
        self.key = key
    }

    var hasCompletedTutorial: Bool {
        get { defaults.bool(forKey: key) }
        set { defaults.set(newValue, forKey: key) }
    }
}

final class InMemoryTutorialCompletionStore: TutorialCompletionStoring {
    var hasCompletedTutorial: Bool

    init(hasCompletedTutorial: Bool = false) {
        self.hasCompletedTutorial = hasCompletedTutorial
    }
}
