import SwiftUI

struct TicketCreationStepIndicatorView: View {
    let activeStep: Int

    private let steps = [
        "内容",
        "イラスト",
        "背景・枠",
        "プレビュー"
    ]

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            ForEach(Array(steps.enumerated()), id: \.offset) { index, title in
                stepView(number: index + 1, title: title)
                    .frame(maxWidth: .infinity)
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .contain)
    }

    private func stepView(number: Int, title: String) -> some View {
        let isActive = number == activeStep

        return VStack(spacing: 6) {
            Text("\(number)")
                .font(.system(.caption, design: .rounded, weight: .bold))
                .foregroundStyle(isActive ? Color.white : AppColors.textSecondary)
                .frame(width: 28, height: 28)
                .background(isActive ? AppColors.primary : AppColors.primarySoft)
                .clipShape(Circle())

            Text(title)
                .font(.system(.caption2, design: .rounded, weight: isActive ? .bold : .medium))
                .foregroundStyle(
                    isActive ? AppColors.primaryDark : AppColors.textSecondary
                )
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "ステップ\(number)、\(title)\(isActive ? "、現在のステップ" : "")"
        )
    }
}

#Preview {
    TicketCreationStepIndicatorView(activeStep: 1)
        .padding()
}
