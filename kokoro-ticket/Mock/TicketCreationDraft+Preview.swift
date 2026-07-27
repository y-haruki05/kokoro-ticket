extension TicketCreationDraft {
    static var preview: TicketCreationDraft {
        let draft = TicketCreationDraft()
        draft.selectedIllustration = TicketIllustration(id: "cat_happy")
        draft.ticketTitle = "肩たたき券"
        draft.message = "疲れた時に使ってね。心を込めて肩をたたきます！"
        draft.selectedBackgroundColor = .lightBlue
        draft.selectedBorderStyle = .roundedBold
        return draft
    }

    static var inputPreview: TicketCreationDraft {
        let draft = TicketCreationDraft()
        draft.ticketTitle = "ぎゅー券"
        draft.message = "寂しい時や元気が欲しい時に使ってね。ぎゅっと抱きしめます！"
        return draft
    }

    static var longTextPreview: TicketCreationDraft {
        let draft = TicketCreationDraft()
        draft.selectedIllustration = TicketIllustration(id: "cat_ticket")
        draft.ticketTitle = "なんでもお願い券"
        draft.message = "困った時や手を貸してほしい時に使ってね。できることを一つ、心を込めてお手伝いします！"
        draft.selectedBackgroundColor = .lightPink
        draft.selectedBorderStyle = .double
        return draft
    }
}
