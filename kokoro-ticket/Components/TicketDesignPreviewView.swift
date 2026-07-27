import SwiftUI

struct TicketDesignPreviewView: View {
    let illustration: TicketIllustration?
    let content: TicketContent
    let design: TicketDesign

    var body: some View {
        TicketVisualView(
            title: content.ticketTitle,
            message: content.message,
            illustration: illustration,
            design: design,
            size: .large
        )
    }
}

#Preview {
    TicketDesignPreviewView(
        illustration: TicketIllustration(id: "cat_happy"),
        content: TicketContent(
            ticketTitle: "肩たたき券",
            message: "疲れた時に使ってね。心を込めて肩をたたきます！"
        ),
        design: TicketDesign(
            backgroundColor: .lightYellow,
            borderStyle: .dashed
        )
    )
    .padding()
    .background(AppColors.background)
}
