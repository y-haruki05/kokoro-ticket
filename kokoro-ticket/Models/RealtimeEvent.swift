import Foundation

/// Realtimeイベント後に再取得すべきStoreの領域
enum RealtimeDataArea: Sendable, Equatable {
    case friends
    case tickets
    case notifications
}

struct RealtimeEvent: Sendable, Equatable {
    let area: RealtimeDataArea
    let table: String
}

enum RealtimeConnectionStatus: Sendable, Equatable {
    case disconnected
    case connecting
    case connected
}
