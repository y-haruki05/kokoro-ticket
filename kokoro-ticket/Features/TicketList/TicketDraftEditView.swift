import SwiftUI

struct TicketDraftEditView: View {
    let ticket: TicketListItem
    let onSave: (String, String) -> Bool

    @Environment(\.dismiss) private var dismiss
    @State private var title: String
    @State private var message: String

    init(
        ticket: TicketListItem,
        onSave: @escaping (String, String) -> Bool
    ) {
        self.ticket = ticket
        self.onSave = onSave
        _title = State(initialValue: ticket.title)
        _message = State(initialValue: ticket.message)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    TicketInputField(
                        title: "チケット名",
                        placeholder: "肩たたき券",
                        text: $title
                    )

                    TicketMessageInputField(
                        title: "メッセージ",
                        placeholder: "ありがとうの気持ちを書こう",
                        text: $message
                    )
                }
                .padding(20)
            }
            .background(AppColors.background.ignoresSafeArea())
            .navigationTitle("作り置きを編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        if onSave(title, message) {
                            dismiss()
                        }
                    }
                    .fontWeight(.bold)
                }
            }
        }
    }
}

#Preview {
    TicketDraftEditView(
        ticket: MockTicketListItems.items[0],
        onSave: { _, _ in true }
    )
}
