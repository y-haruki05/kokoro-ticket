import SwiftUI

struct TicketDesignPreviewView: View {
    let illustration: TicketIllustration?
    let content: TicketContent
    let design: TicketDesign

    var body: some View {
        VStack(spacing: 14) {
            IllustrationPlaceholderView(compact: true)
                .frame(width: 108, height: 74)

            VStack(spacing: 5) {
                Text(content.ticketTitle.valueOrFallback("肩たたき券"))
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(AppColors.primaryDark)

                Text(content.message.valueOrFallback("ありがとうの気持ちをこめて"))
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }

            Text("作り置きチケット")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(AppColors.primaryDark)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(AppColors.primarySoft)
                .clipShape(Capsule())
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(design.backgroundColor.color)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay {
            TicketBorderShape(
                style: design.borderStyle,
                color: AppColors.primary
            )
        }
        .shadow(color: AppColors.shadow, radius: 12, y: 6)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            illustration == nil
                ? "イラスト未選択のチケットプレビュー"
                : "選択したイラストのチケットプレビュー"
        )
    }

}

private extension String {
    func valueOrFallback(_ fallback: String) -> String {
        trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? fallback : self
    }
}

#Preview {
    TicketDesignPreviewView(
        illustration: TicketIllustration(id: "preview"),
        content: TicketContent(),
        design: TicketDesign(
            backgroundColor: .lightYellow,
            borderStyle: .dashed
        )
    )
    .padding()
    .background(AppColors.background)
}
