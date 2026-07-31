import SwiftUI

struct TicketConfirmationView: View {
    let draft: TicketCreationDraft
    let onBack: () -> Void
    var onSave: (TicketCreationDraftSnapshot) -> Bool = { _ in true }
    var onSaveCompleted: () -> Void = {}

    @State private var isSaving = false
    @State private var isShowingSaveConfirmation = false
    @State private var isShowingSaveError = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                TicketCreationHeaderView(onBack: onBack)

                TicketCreationStepIndicatorView(activeStep: 4)

                VStack(alignment: .leading, spacing: 20) {
                    Text("できあがり！")
                        .font(.system(.title2, design: .rounded, weight: .bold))
                        .foregroundStyle(AppColors.textPrimary)

                    Text("大切な気持ちが届くように、最後に確認してみよう")
                        .font(.system(.subheadline, design: .rounded, weight: .medium))
                        .foregroundStyle(AppColors.textSecondary)

                    TicketConfirmationSummaryView(draft: draft)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .background(AppColors.background.ignoresSafeArea())
        .navigationBarHidden(true)
        .sensoryFeedback(.success, trigger: isShowingSaveConfirmation)
        .sensoryFeedback(.error, trigger: isShowingSaveError)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            TicketCreationNavigationButtons(
                primaryTitle: "保存する",
                onBack: onBack,
                onNext: saveTicket,
                isPrimaryDisabled: isSaving
            )
        }
        .overlay {
            if isShowingSaveConfirmation {
                TicketCreationSaveSuccessView()
                    .transition(.opacity)
                    .accessibilityAddTraits(.isStaticText)
            } else if isShowingSaveError {
                TicketCreationFeedbackView(
                    imageName: "cat_sad",
                    title: "保存できませんでした",
                    message: "入力内容はそのままです。もう一度お試しください。"
                )
                .transition(.opacity)
                .onTapGesture {
                    withAnimation(.easeOut(duration: 0.2)) {
                        isShowingSaveError = false
                    }
                }
            }
        }
    }

    private func saveTicket() {
        guard !isSaving else { return }
        isSaving = true
        isShowingSaveError = false

        guard onSave(draft.snapshot) else {
            isSaving = false
            withAnimation(.easeInOut(duration: 0.2)) {
                isShowingSaveError = true
            }
            return
        }

        withAnimation(.easeInOut(duration: 0.2)) {
            isShowingSaveConfirmation = true
        }

        Task { @MainActor in
            do {
                try await Task.sleep(nanoseconds: 900_000_000)
            } catch {
                return
            }
            onSaveCompleted()
        }
    }
}

struct TicketCreationSaveSuccessView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image("cat_happy")
                .resizable()
                .scaledToFit()
                .frame(width: 132, height: 104)

            Text("チケットを保存しました！")
                .font(.system(.headline, design: .rounded, weight: .bold))
                .foregroundStyle(AppColors.primaryDark)

            Text("あとからフレンドへ送れます")
                .font(.system(.subheadline, design: .rounded, weight: .medium))
                .foregroundStyle(AppColors.textSecondary)
        }
        .padding(26)
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

#Preview {
    NavigationStack {
        TicketConfirmationView(
            draft: .preview,
            onBack: {}
        )
    }
}

#Preview("保存失敗") {
    NavigationStack {
        TicketConfirmationView(
            draft: .preview,
            onBack: {},
            onSave: { _ in false }
        )
    }
}

#Preview("保存成功") {
    TicketCreationSaveSuccessView()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.background)
}
