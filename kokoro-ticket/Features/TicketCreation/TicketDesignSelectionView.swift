import SwiftUI

struct TicketDesignSelectionView: View {
    let illustration: TicketIllustration?
    let content: TicketContent
    let onBack: () -> Void
    let onNext: (TicketDesign) -> Void

    @State private var selectedBackgroundColor: TicketBackgroundColor
    @State private var selectedBorderStyle: TicketBorderStyle

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    init(
        illustration: TicketIllustration?,
        content: TicketContent,
        initialDesign: TicketDesign = TicketDesign(),
        onBack: @escaping () -> Void,
        onNext: @escaping (TicketDesign) -> Void = { _ in }
    ) {
        self.illustration = illustration
        self.content = content
        self.onBack = onBack
        self.onNext = onNext
        _selectedBackgroundColor = State(
            initialValue: initialDesign.backgroundColor
        )
        _selectedBorderStyle = State(initialValue: initialDesign.borderStyle)
    }

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
                                    selectedBackgroundColor = option
                                } label: {
                                    TicketBackgroundColorOptionView(
                                        option: option,
                                        isSelected: selectedBackgroundColor == option
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
                                    selectedBorderStyle = style
                                } label: {
                                    TicketBorderStyleOptionView(
                                        style: style,
                                        isSelected: selectedBorderStyle == style
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    optionSection(title: "プレビュー") {
                        TicketDesignPreviewView(
                            illustration: illustration,
                            content: content,
                            design: currentDesign
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
                onNext: {
                    onNext(currentDesign)
                }
            )
        }
    }

    private var currentDesign: TicketDesign {
        TicketDesign(
            backgroundColor: selectedBackgroundColor,
            borderStyle: selectedBorderStyle
        )
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
            illustration: TicketIllustration(id: "preview"),
            content: TicketContent(
                ticketTitle: "肩たたき券",
                message: "いつもありがとう",
                sender: "ゆうせい",
                receiver: "おかあさん"
            ),
            onBack: {}
        )
    }
}
