import SwiftUI

/// 画面余白・カード間隔・タップ領域などの共通寸法を定義する
enum AppLayout {
    static let screenHorizontalPadding: CGFloat = 20
    static let sectionSpacing: CGFloat = 22
    static let cardSpacing: CGFloat = 14
    static let cardPadding: CGFloat = 16
    static let cardCornerRadius: CGFloat = 22
    static let controlCornerRadius: CGFloat = 18
    static let buttonHeight: CGFloat = 54
    static let minimumTapTarget: CGFloat = 44
    static let stateImageSize: CGFloat = 112
}

enum AppTypography {
    static let screenTitle = Font.system(.title2, design: .rounded, weight: .bold)
    static let sectionTitle = Font.system(.title3, design: .rounded, weight: .bold)
    static let cardTitle = Font.system(.headline, design: .rounded, weight: .bold)
    static let body = Font.system(.subheadline, design: .rounded, weight: .medium)
    static let caption = Font.system(.caption, design: .rounded, weight: .medium)
    static let button = Font.system(.body, design: .rounded, weight: .bold)
}

struct AppCardModifier: ViewModifier {
    var padding: CGFloat

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(AppColors.cardBackground)
            .clipShape(
                RoundedRectangle(
                    cornerRadius: AppLayout.cardCornerRadius,
                    style: .continuous
                )
            )
            .overlay {
                RoundedRectangle(
                    cornerRadius: AppLayout.cardCornerRadius,
                    style: .continuous
                )
                .stroke(AppColors.border.opacity(0.85), lineWidth: 1)
            }
            .shadow(color: AppColors.shadow, radius: 8, y: 4)
    }
}

extension View {
    func appCard(padding: CGFloat = AppLayout.cardPadding) -> some View {
        modifier(AppCardModifier(padding: padding))
    }

    func appNavigationStyle() -> some View {
        toolbarBackground(AppColors.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
    }
}
