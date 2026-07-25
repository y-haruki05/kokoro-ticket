import SwiftUI

struct TicketCreationNavigationButtons: View {
    let onBack: () -> Void
    let onNext: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            Button(action: onBack) {
                buttonLabel(
                    "戻る",
                    foregroundColor: AppColors.primaryDark,
                    backgroundColor: AppColors.cardBackground
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(AppColors.border, lineWidth: 1.5)
                }
            }
            .buttonStyle(.plain)

            Button(action: onNext) {
                buttonLabel(
                    "次へ",
                    foregroundColor: .white,
                    backgroundColor: AppColors.primary
                )
                .shadow(color: AppColors.shadow, radius: 8, y: 4)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background(.ultraThinMaterial)
    }

    private func buttonLabel(
        _ title: String,
        foregroundColor: Color,
        backgroundColor: Color
    ) -> some View {
        Text(title)
            .font(.system(size: 17, weight: .bold, design: .rounded))
            .foregroundStyle(foregroundColor)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .contentShape(RoundedRectangle(cornerRadius: 18))
    }
}

#Preview {
    TicketCreationNavigationButtons(onBack: {}, onNext: {})
}
