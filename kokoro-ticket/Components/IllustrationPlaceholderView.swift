import SwiftUI

struct IllustrationPlaceholderView: View {
    var compact = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: compact ? 14 : 20)
                .fill(AppColors.primarySoft.opacity(0.65))

            RoundedRectangle(cornerRadius: compact ? 14 : 20)
                .stroke(
                    AppColors.border,
                    style: StrokeStyle(lineWidth: 1.5, dash: [5, 5])
                )

            VStack(spacing: compact ? 4 : 7) {
                Image(systemName: "photo")
                    .font(.system(size: compact ? 20 : 28, weight: .light))
                    .accessibilityHidden(true)

                Text("イラスト")
                    .font(.system(size: compact ? 10 : 12, weight: .medium))
            }
            .foregroundStyle(AppColors.primary)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("イラスト差し替え用プレースホルダー")
    }
}

#Preview {
    IllustrationPlaceholderView()
        .frame(width: 180, height: 120)
        .padding()
}
