import SwiftUI

struct TicketIllustrationSelectionView: View {
    @Bindable var draft: TicketCreationDraft
    let onBack: () -> Void
    var onNext: () -> Void = {}

    private let illustrations = MockTicketIllustrations.candidates
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                TicketCreationHeaderView(onBack: onBack)

                TicketCreationStepIndicatorView(activeStep: 2)

                VStack(alignment: .leading, spacing: 14) {
                    Text("ここにゃんを選ぼう")
                        .font(.system(.title2, design: .rounded, weight: .bold))
                        .foregroundStyle(AppColors.textPrimary)

                    Text("気持ちにぴったりな表情を選んでね")
                        .font(.system(.subheadline, design: .rounded, weight: .medium))
                        .foregroundStyle(AppColors.textSecondary)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 14) {
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
                        .padding(.horizontal, 5)
                        .padding(.vertical, 10)
                    }
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
        .background(AppColors.background.ignoresSafeArea())
        .navigationBarHidden(true)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            TicketCreationNavigationButtons(
                onBack: onBack,
                onNext: onNext,
                isPrimaryDisabled: draft.selectedIllustration == nil
            )
        }
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
