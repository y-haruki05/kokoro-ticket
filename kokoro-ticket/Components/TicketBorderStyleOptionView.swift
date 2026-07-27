import SwiftUI

struct TicketBorderStyleOptionView: View {
    let style: TicketBorderStyle
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 9) {
            TicketBorderShape(style: style, color: AppColors.primary)
                .frame(height: 44)

            Text(style.displayName)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(AppColors.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(10)
        .frame(maxWidth: .infinity)
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .stroke(
                    isSelected ? AppColors.primary : AppColors.border,
                    lineWidth: isSelected ? 2.5 : 1
                )
        }
        .shadow(
            color: isSelected ? AppColors.shadow : .clear,
            radius: 10,
            y: isSelected ? 5 : 0
        )
        .offset(y: isSelected ? -2 : 0)
        .animation(.spring(response: 0.25, dampingFraction: 0.82), value: isSelected)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

struct TicketBorderShape: View {
    let style: TicketBorderStyle
    let color: Color

    var body: some View {
        switch style {
        case .simple:
            RoundedRectangle(cornerRadius: 10)
                .stroke(color, lineWidth: 1.5)
        case .dashed:
            RoundedRectangle(cornerRadius: 10)
                .stroke(
                    color,
                    style: StrokeStyle(lineWidth: 1.8, dash: [6, 4])
                )
        case .double:
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(color, lineWidth: 1.5)
                RoundedRectangle(cornerRadius: 7)
                    .inset(by: 4)
                    .stroke(color, lineWidth: 1)
            }
        case .roundedBold:
            RoundedRectangle(cornerRadius: 16)
                .stroke(color, lineWidth: 4)
        }
    }
}

#Preview {
    HStack {
        TicketBorderStyleOptionView(style: .dashed, isSelected: false)
        TicketBorderStyleOptionView(style: .roundedBold, isSelected: true)
    }
    .padding()
    .background(AppColors.background)
}
