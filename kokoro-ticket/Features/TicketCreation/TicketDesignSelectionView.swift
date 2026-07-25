import SwiftUI

struct TicketDesignSelectionView: View {
    @Bindable var draft: TicketCreationDraft
    let onBack: () -> Void
    var onNext: () -> Void = {}

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                TicketCreationHeaderView(onBack: onBack)

                TicketCreationStepIndicatorView(activeStep: 3)

                VStack(alignment: .leading, spacing: 24) {
                    Text("デザインを選ぼう")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(AppColors.textPrimary)

                    optionSection(title: "背景色") {
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(TicketBackgroundColor.allCases) { option in
                                Button {
                                    draft.selectedBackgroundColor = option
                                } label: {
                                    TicketBackgroundColorOptionView(
                                        option: option,
                                        isSelected: draft.selectedBackgroundColor == option
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    optionSection(title: "枠デザイン") {
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(TicketBorderStyle.allCases) { style in
                                Button {
                                    draft.selectedBorderStyle = style
                                } label: {
                                    TicketBorderStyleOptionView(
                                        style: style,
                                        isSelected: draft.selectedBorderStyle == style
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    optionSection(title: "プレビュー") {
                        TicketDesignPreviewView(
                            illustration: draft.selectedIllustration,
                            content: draft.content,
                            design: draft.design
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

    private func optionSection<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(AppColors.textPrimary)

            content()
        }
    }
}

#Preview {
    NavigationStack {
        TicketDesignSelectionView(
            draft: TicketCreationDraft.preview,
            onBack: {}
        )
    }
}
