import Observation

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
