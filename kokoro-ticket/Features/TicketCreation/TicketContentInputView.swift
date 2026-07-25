import SwiftUI

struct TicketContentInputView: View {
    let onBack: () -> Void
    let onNext: (TicketContent) -> Void

    @State private var ticketTitle: String
    @State private var message: String
    @State private var sender: String
    @State private var receiver: String

    init(
        initialContent: TicketContent = TicketContent(),
        onBack: @escaping () -> Void,
        onNext: @escaping (TicketContent) -> Void = { _ in }
    ) {
        self.onBack = onBack
        self.onNext = onNext
        _ticketTitle = State(initialValue: initialContent.ticketTitle)
        _message = State(initialValue: initialContent.message)
        _sender = State(initialValue: initialContent.sender)
        _receiver = State(initialValue: initialContent.receiver)
    }

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
                            text: $ticketTitle
                        )

                        TicketMessageInputField(
                            title: "メッセージ",
                            placeholder: "ありがとうの気持ちを書こう",
                            text: $message
                        )

                        TicketInputField(
                            title: "差出人",
                            placeholder: "ゆうせい",
                            text: $sender
                        )

                        TicketInputField(
                            title: "宛先",
                            placeholder: "おかあさん",
                            text: $receiver
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
            navigationButtons
        }
    }

    private var navigationButtons: some View {
        HStack(spacing: 14) {
            Button(action: onBack) {
                Text("戻る")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .contentShape(Rectangle())
            }
            .foregroundStyle(AppColors.primaryDark)
            .background(AppColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay {
                RoundedRectangle(cornerRadius: 18)
                    .stroke(AppColors.border, lineWidth: 1.5)
            }
            .buttonStyle(.plain)

            Button {
                onNext(
                    TicketContent(
                        ticketTitle: ticketTitle,
                        message: message,
                        sender: sender,
                        receiver: receiver
                    )
                )
            } label: {
                Text("次へ")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .contentShape(Rectangle())
            }
            .foregroundStyle(.white)
            .background(AppColors.primary)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .shadow(color: AppColors.shadow, radius: 8, y: 4)
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background(.ultraThinMaterial)
    }
}

#Preview {
    NavigationStack {
        TicketContentInputView(onBack: {})
    }
}
