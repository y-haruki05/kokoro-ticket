import SwiftUI

struct IllustrationSelectionCard: View {
    let illustration: TicketIllustration
    let isSelected: Bool

    var body: some View {
        Image(illustration.assetName)
            .resizable()
            .scaledToFit()
            .padding(10)
            .frame(width: 104, height: 104)
            .background(isSelected ? AppColors.primarySoft : AppColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .overlay {
                RoundedRectangle(cornerRadius: 24)
                    .stroke(
                        isSelected ? AppColors.primary : AppColors.border,
                        lineWidth: isSelected ? 2.5 : 1
                    )
            }
            .shadow(
                color: isSelected ? AppColors.shadow.opacity(0.8) : .clear,
                radius: 8,
                y: 4
            )
            .scaleEffect(isSelected ? 1.05 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.78), value: isSelected)
            .accessibilityLabel("ここにゃん")
            .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview {
    HStack {
        IllustrationSelectionCard(
            illustration: TicketIllustration(id: "cat_default"),
            isSelected: false
        )

        IllustrationSelectionCard(
            illustration: TicketIllustration(id: "cat_happy"),
            isSelected: true
        )
    }
    .padding()
    .background(AppColors.background)
}
