import Observation

/// 作成フローの各画面で共有する、保存前の入力内容とデザイン選択状態
@Observable
final class TicketCreationDraft {
    var selectedIllustration: TicketIllustration?
    var ticketTitle = ""
    var message = ""
    var selectedBackgroundColor: TicketBackgroundColor = .white
    var selectedBorderStyle: TicketBorderStyle = .simple

    var content: TicketContent {
        TicketContent(
            ticketTitle: ticketTitle,
            message: message
        )
    }

    var design: TicketDesign {
        TicketDesign(
            backgroundColor: selectedBackgroundColor,
            borderStyle: selectedBorderStyle
        )
    }

    var snapshot: TicketCreationDraftSnapshot {
        TicketCreationDraftSnapshot(
            selectedIllustration: selectedIllustration,
            content: content,
            design: design
        )
    }

    func reset() {
        selectedIllustration = nil
        ticketTitle = ""
        message = ""
        selectedBackgroundColor = .white
        selectedBorderStyle = .simple
    }
}

struct TicketCreationDraftSnapshot: Hashable {
    let selectedIllustration: TicketIllustration?
    let content: TicketContent
    let design: TicketDesign
}
