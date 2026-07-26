import Foundation

enum RealtimeDataArea: Sendable, Equatable {
    case friends
    case tickets
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
