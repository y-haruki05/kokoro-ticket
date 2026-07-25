import SwiftUI

struct TicketCreationStepIndicatorView: View {
    let activeStep: Int

    private let steps = [
        "イラスト",
        "内容入力",
        "デザイン",
        "確認"
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

        return VStack(spacing: 7) {
            Text("\(number)")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(isActive ? Color.white : AppColors.textSecondary)
                .frame(width: 30, height: 30)
                .background(isActive ? AppColors.primary : AppColors.primarySoft)
                .clipShape(Circle())

            Text(title)
                .font(.system(size: 11, weight: isActive ? .bold : .medium))
                .foregroundStyle(
                    isActive ? AppColors.primaryDark : AppColors.textSecondary
                )
                .lineLimit(1)
                .minimumScaleFactor(0.8)
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
