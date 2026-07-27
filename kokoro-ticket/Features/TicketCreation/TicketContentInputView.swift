import SwiftUI

struct TicketContentInputView: View {
    @Bindable var draft: TicketCreationDraft
    let onBack: () -> Void
    var onNext: () -> Void = {}
    var automaticallyFocusTitle = false

    @State private var isShowingInputGuide = false
    @FocusState private var focusedField: TicketInputFocus?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                TicketCreationHeaderView(onBack: onBack)

                TicketCreationStepIndicatorView(activeStep: 1)

                VStack(alignment: .leading, spacing: 16) {
                    Text("どんなチケットを作る？")
                        .font(.system(.title2, design: .rounded, weight: .bold))
                        .foregroundStyle(AppColors.textPrimary)

                    Text("相手にしてあげたいことを、チケットにしてみよう")
                        .font(.system(.subheadline, design: .rounded, weight: .medium))
                        .foregroundStyle(AppColors.textSecondary)

                    VStack(spacing: 18) {
                        TicketInputField(
                            title: "チケット名",
                            placeholder: "例：肩たたき券",
                            text: $draft.ticketTitle,
                            supportingText: "相手が使える内容を「○○券」の形で書いてみよう",
                            characterLimit: 20,
                            focusedField: $focusedField,
                            onSubmit: {
                                focusedField = .message
                            }
                        )

                        TicketMessageInputField(
                            title: "ひとことメッセージ",
                            placeholder: "例：疲れた日に使ってね。心を込めて肩をたたきます！",
                            text: $draft.message,
                            supportingText: "このチケットの使い方や、相手へ伝えたい気持ちを書いてみよう",
                            characterLimit: 100,
                            focusedField: $focusedField
                        )
                    }
                    .padding(20)
                    .background(AppColors.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .overlay {
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(AppColors.border.opacity(0.8), lineWidth: 1)
                    }
                    .shadow(color: AppColors.shadow.opacity(0.65), radius: 10, y: 5)
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("プレビュー")
                        .font(.system(.headline, design: .rounded, weight: .bold))
                        .foregroundStyle(AppColors.textPrimary)

                    TicketDesignPreviewView(
                        illustration: draft.selectedIllustration,
                        content: draft.content,
                        design: draft.design
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(AppColors.background.ignoresSafeArea())
        .navigationBarHidden(true)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            TicketCreationNavigationButtons(
                onBack: onBack,
                onNext: validateAndContinue
            )
        }
        .overlay {
            if isShowingInputGuide {
                TicketCreationFeedbackView(
                    imageName: "cat_sad",
                    title: "もう少しだけ教えてね",
                    message: "チケット名を入力すると、次へ進めます。"
                )
                .transition(.opacity.combined(with: .scale(scale: 0.96)))
                .onTapGesture {
                    withAnimation(.easeOut(duration: 0.2)) {
                        isShowingInputGuide = false
                    }
                }
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()

                Button("完了") {
                    focusedField = nil
                }
                .fontWeight(.semibold)
            }
        }
        .task {
            guard automaticallyFocusTitle else { return }
            try? await Task.sleep(for: .milliseconds(250))
            focusedField = .title
        }
    }

    private func validateAndContinue() {
        let title = draft.ticketTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let message = draft.message.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !title.isEmpty else {
            withAnimation(.easeOut(duration: 0.2)) {
                isShowingInputGuide = true
            }
            return
        }

        draft.ticketTitle = title
        draft.message = message
        onNext()
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

#Preview("入力中") {
    NavigationStack {
        TicketContentInputView(
            draft: .inputPreview,
            onBack: {}
        )
    }
}

#Preview("長文入力") {
    NavigationStack {
        TicketContentInputView(
            draft: .longTextPreview,
            onBack: {}
        )
    }
}

#Preview("エラー") {
    TicketCreationFeedbackView(
        imageName: "cat_sad",
        title: "もう少しだけ教えてね",
        message: "チケット名を入力すると、次へ進めます。"
    )
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(AppColors.background)
}

#Preview("Dark Mode") {
    NavigationStack {
        TicketContentInputView(
            draft: .preview,
            onBack: {}
        )
    }
    .preferredColorScheme(.dark)
}

struct TicketCreationFeedbackView: View {
    let imageName: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 12) {
            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 112, height: 88)

            Text(title)
                .font(.system(.headline, design: .rounded, weight: .bold))
                .foregroundStyle(AppColors.primaryDark)

            Text(message)
                .font(.system(.subheadline, design: .rounded, weight: .medium))
                .foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .frame(maxWidth: 300)
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 26))
        .overlay {
            RoundedRectangle(cornerRadius: 26)
                .stroke(AppColors.border, lineWidth: 1)
        }
        .shadow(color: AppColors.shadow, radius: 18, y: 8)
        .padding()
    }
}
