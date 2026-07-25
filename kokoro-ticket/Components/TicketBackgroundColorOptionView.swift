import SwiftUI

struct TicketBackgroundColorOptionView: View {
    let option: TicketBackgroundColor
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 9) {
            RoundedRectangle(cornerRadius: 12)
                .fill(option.color)
                .frame(height: 44)
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppColors.border.opacity(0.8), lineWidth: 1)
                }

            Text(option.displayName)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(
                    isSelected ? AppColors.primaryDark : AppColors.textSecondary
                )
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(10)
        .frame(maxWidth: .infinity)
        .background(
            isSelected ? AppColors.primarySoft : AppColors.cardBackground
        )
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .stroke(
                    isSelected ? AppColors.primary : AppColors.border,
                    lineWidth: isSelected ? 2.5 : 1
                )
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

extension TicketBackgroundColor {
    var color: Color {
        switch self {
        case .white: AppColors.cardBackground
        case .lightBlue: AppColors.pastelBlue
        case .lightPink: AppColors.pastelPink
        case .lightYellow: AppColors.pastelYellow
        }
    }
}

#Preview {
    HStack {
        TicketBackgroundColorOptionView(option: .white, isSelected: false)
        TicketBackgroundColorOptionView(option: .lightBlue, isSelected: true)
    }
    .padding()
    .background(AppColors.background)
}
