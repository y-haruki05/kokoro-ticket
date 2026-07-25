import SwiftUI

struct TicketCreationNavigationButtons: View {
    let onBack: () -> Void
    let onNext: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            Button(action: onBack) {
                buttonLabel("戻る")
            }
            .foregroundStyle(AppColors.primaryDark)
            .background(AppColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay {
                RoundedRectangle(cornerRadius: 18)
                    .stroke(AppColors.border, lineWidth: 1.5)
            }
            .buttonStyle(.plain)

            Button(action: onNext) {
                buttonLabel("次へ")
            }
            .foregroundStyle(.white)
            .background(AppColors.primary)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .shadow(color: AppColors.shadow, radius: 8, y: 4)
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background(.ultraThinMaterial)
    }

    private func buttonLabel(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 17, weight: .bold, design: .rounded))
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .contentShape(Rectangle())
    }
}

#Preview {
    TicketCreationNavigationButtons(onBack: {}, onNext: {})
}
