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
                        placeholder: "例：肩たたき券",
                        text: $title,
                        supportingText: "相手が使える内容を「○○券」の形で書いてみよう",
                        characterLimit: 20
                    )

                    TicketMessageInputField(
                        title: "ひとことメッセージ",
                        placeholder: "例：疲れた日に使ってね。心を込めて肩をたたきます！",
                        text: $message,
                        supportingText: "このチケットの使い方や、相手へ伝えたい気持ちを書いてみよう",
                        characterLimit: 100
                    )
                }
                .padding(20)
            }
            .background(AppColors.background.ignoresSafeArea())
            .navigationTitle("チケットを編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        let normalizedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
                        let normalizedMessage = message.trimmingCharacters(in: .whitespacesAndNewlines)
                        if onSave(normalizedTitle, normalizedMessage) {
                            dismiss()
                        }
                    }
                    .fontWeight(.bold)
                    .disabled(
                        title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    )
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
