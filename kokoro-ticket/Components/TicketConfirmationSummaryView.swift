import SwiftUI

struct TicketConfirmationSummaryView: View {
    let draft: TicketCreationDraft

    var body: some View {
        VStack(spacing: 16) {
            TicketDesignPreviewView(
                illustration: draft.selectedIllustration,
                content: draft.content,
                design: draft.design
            )

            HStack(spacing: 10) {
                designDetail(
                    title: "背景色",
                    value: draft.selectedBackgroundColor.displayName
                )

                designDetail(
                    title: "枠デザイン",
                    value: draft.selectedBorderStyle.displayName
                )
            }
        }
    }

    private func designDetail(title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(AppColors.textSecondary)

            Text(value)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(AppColors.primaryDark)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(AppColors.primarySoft)
        .clipShape(RoundedRectangle(cornerRadius: 15))
    }
}

#Preview {
    TicketConfirmationSummaryView(draft: .preview)
        .padding()
        .background(AppColors.background)
}
