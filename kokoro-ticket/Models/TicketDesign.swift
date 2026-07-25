import Foundation

enum TicketBackgroundColor: String, CaseIterable, Identifiable {
    case white
    case lightBlue
    case lightPink
    case lightYellow

    var id: Self { self }

    var displayName: String {
        switch self {
        case .white: "ホワイト"
        case .lightBlue: "ライトブルー"
        case .lightPink: "ライトピンク"
        case .lightYellow: "ライトイエロー"
        }
    }
}

enum TicketBorderStyle: String, CaseIterable, Identifiable {
    case simple
    case dashed
    case double
    case roundedBold

    var id: Self { self }

    var displayName: String {
        switch self {
        case .simple: "シンプル"
        case .dashed: "点線"
        case .double: "二重線"
        case .roundedBold: "丸みのある枠"
        }
    }
}

struct TicketDesign: Hashable {
    var backgroundColor: TicketBackgroundColor = .white
    var borderStyle: TicketBorderStyle = .simple
}
