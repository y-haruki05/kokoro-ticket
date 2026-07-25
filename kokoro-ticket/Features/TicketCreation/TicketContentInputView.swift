import SwiftUI

struct TicketContentInputView: View {
    @Bindable var draft: TicketCreationDraft
    let onBack: () -> Void
    var onNext: () -> Void = {}

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                TicketCreationHeaderView(onBack: onBack)

                TicketCreationStepIndicatorView(activeStep: 2)

                VStack(alignment: .leading, spacing: 20) {
                    Text("チケットの内容を入力しよう")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(AppColors.textPrimary)

                    VStack(spacing: 18) {
                        TicketInputField(
                            title: "チケット名",
                            placeholder: "肩たたき券",
                            text: $draft.ticketTitle
                        )

                        TicketMessageInputField(
                            title: "メッセージ",
                            placeholder: "ありがとうの気持ちを書こう",
                            text: $draft.message
                        )

                        TicketInputField(
                            title: "差出人",
                            placeholder: "ゆうせい",
                            text: $draft.sender
                        )

                        TicketInputField(
                            title: "宛先",
                            placeholder: "おかあさん",
                            text: $draft.receiver
                        )
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .background(AppColors.background.ignoresSafeArea())
        .navigationBarHidden(true)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            TicketCreationNavigationButtons(
                onBack: onBack,
                onNext: onNext
            )
        }
    }
}

#Preview {
    NavigationStack {
        TicketContentInputView(
            draft: TicketCreationDraft(),
            onBack: {}
        )
    }
}
