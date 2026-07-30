import SwiftUI

struct TicketBackgroundColorOptionView: View {
    let option: TicketBackgroundColor
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 9) {
            Circle()
                .fill(option.color)
                .frame(width: 54, height: 54)
                .overlay {
                    Circle()
                        .stroke(AppColors.border.opacity(0.8), lineWidth: 1)
                }
                .overlay {
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(AppColors.primaryDark)
                    }
                }

            Text(option.displayName)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(
                    isSelected ? AppColors.primaryDark : AppColors.textSecondary
                )
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

extension TicketBackgroundColor {
    var color: Color {
        switch self {
        case .white: AppColors.ticketWhite
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
