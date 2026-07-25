import SwiftUI

struct IllustrationSelectionCard: View {
    let illustration: TicketIllustration
    let isSelected: Bool

    var body: some View {
        Text("イラスト挿入予定")
            .font(.system(size: 14, weight: .semibold, design: .rounded))
            .foregroundStyle(AppColors.textSecondary)
            .frame(maxWidth: .infinity)
            .frame(height: 136)
            .background(
                isSelected
                    ? AppColors.primarySoft
                    : AppColors.cardBackground
            )
            .clipShape(RoundedRectangle(cornerRadius: 22))
            .overlay {
                RoundedRectangle(cornerRadius: 22)
                    .stroke(
                        isSelected ? AppColors.primary : AppColors.border,
                        lineWidth: isSelected ? 2.5 : 1
                    )
            }
            .shadow(
                color: isSelected ? .clear : AppColors.shadow,
                radius: 8,
                y: 4
            )
            .accessibilityLabel("イラスト候補")
            .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview {
    HStack {
        IllustrationSelectionCard(
            illustration: TicketIllustration(id: "preview-01"),
            isSelected: false
        )

        IllustrationSelectionCard(
            illustration: TicketIllustration(id: "preview-02"),
            isSelected: true
        )
    }
    .padding()
    .background(AppColors.background)
}
