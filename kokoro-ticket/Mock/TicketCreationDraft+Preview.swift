extension TicketCreationDraft {
    static var preview: TicketCreationDraft {
        let draft = TicketCreationDraft()
        draft.selectedIllustration = TicketIllustration(id: "preview")
        draft.ticketTitle = "肩たたき券"
        draft.message = "いつもありがとう"
        draft.selectedBackgroundColor = .lightBlue
        draft.selectedBorderStyle = .roundedBold
        return draft
    }
}
