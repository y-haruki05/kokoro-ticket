import SwiftUI

struct TicketConfirmationView: View {
    let draft: TicketCreationDraft
    let onBack: () -> Void
    var onSave: (TicketCreationDraftSnapshot) -> Void = { _ in }
    var onSaveCompleted: () -> Void = {}

    @State private var isSaving = false
    @State private var isShowingSaveConfirmation = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                TicketCreationHeaderView(onBack: onBack)

                TicketCreationStepIndicatorView(activeStep: 4)

                VStack(alignment: .leading, spacing: 20) {
                    Text("完成したチケットを確認しよう")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(AppColors.textPrimary)

                    TicketConfirmationSummaryView(draft: draft)
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
                primaryTitle: "保存",
                onBack: onBack,
                onNext: saveTicket
            )
        }
        .overlay {
            if isShowingSaveConfirmation {
                Text("チケットを保存しました")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 15)
                    .background(AppColors.primaryDark)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: AppColors.shadow, radius: 10, y: 5)
                    .transition(.opacity)
                    .accessibilityAddTraits(.isStaticText)
            }
        }
    }

    private func saveTicket() {
        guard !isSaving else { return }
        isSaving = true
        onSave(draft.snapshot)

        withAnimation(.easeInOut(duration: 0.2)) {
            isShowingSaveConfirmation = true
        }

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 900_000_000)
            onSaveCompleted()
        }
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
