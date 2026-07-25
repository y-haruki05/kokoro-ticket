import SwiftUI

struct TicketIllustrationSelectionView: View {
    @Bindable var draft: TicketCreationDraft
    let onBack: () -> Void
    var onNext: () -> Void = {}

    private let illustrations = MockTicketIllustrations.candidates
    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                TicketCreationHeaderView(onBack: onBack)

                TicketCreationStepIndicatorView(activeStep: 1)

                VStack(alignment: .leading, spacing: 18) {
                    Text("イラストを選ぼう")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(AppColors.textPrimary)

                    LazyVGrid(columns: columns, spacing: 14) {
                        ForEach(illustrations) { illustration in
                            Button {
                                draft.selectedIllustration = illustration
                            } label: {
                                IllustrationSelectionCard(
                                    illustration: illustration,
                                    isSelected: draft.selectedIllustration == illustration
                                )
                            }
                            .buttonStyle(.plain)
                        }
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
            nextButton
        }
    }

    private var nextButton: some View {
        Button(action: onNext) {
            Text("次へ")
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(
                    draft.selectedIllustration == nil
                        ? AppColors.textSecondary.opacity(0.35)
                        : AppColors.primary
                )
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .contentShape(RoundedRectangle(cornerRadius: 18))
        }
        .buttonStyle(.plain)
        .disabled(draft.selectedIllustration == nil)
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background(.ultraThinMaterial)
    }
}

#Preview {
    NavigationStack {
        TicketIllustrationSelectionView(
            draft: TicketCreationDraft(),
            onBack: {}
        )
    }
}
