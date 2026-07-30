import SwiftUI
import UIKit

enum AppColors {
    static let primary = Color(red: 0.30, green: 0.67, blue: 0.88)
    static let primaryDark = Color(red: 0.20, green: 0.45, blue: 0.64)
    static let primarySoft = adaptive(
        light: UIColor(red: 0.90, green: 0.97, blue: 1.00, alpha: 1),
        dark: UIColor(red: 0.10, green: 0.22, blue: 0.29, alpha: 1)
    )
    static let pastelBlue = Color(red: 0.89, green: 0.96, blue: 1.00)
    static let pastelPink = Color(red: 1.00, green: 0.92, blue: 0.94)
    static let pastelYellow = Color(red: 1.00, green: 0.97, blue: 0.82)
    static let background = adaptive(
        light: .white,
        dark: UIColor(red: 0.07, green: 0.10, blue: 0.13, alpha: 1)
    )
    static let cardBackground = adaptive(
        light: .white,
        dark: UIColor.secondarySystemBackground
    )
    // A ticket is a paper-like object and keeps its selected light surface in
    // both appearances. Screen and card surfaces remain adaptive.
    static let ticketWhite = Color.white
    static let ticketTextSecondary = Color(red: 0.36, green: 0.40, blue: 0.44)
    static let textPrimary = Color(uiColor: .label)
    static let textSecondary = Color(uiColor: .secondaryLabel)
    static let border = adaptive(
        light: UIColor(red: 0.72, green: 0.87, blue: 0.96, alpha: 1),
        dark: UIColor(red: 0.24, green: 0.43, blue: 0.55, alpha: 1)
    )
    static let divider = Color(uiColor: .separator)
    static let success = Color(red: 0.24, green: 0.66, blue: 0.47)
    static let error = Color(red: 0.82, green: 0.28, blue: 0.31)
    static let shadow = Color(red: 0.20, green: 0.45, blue: 0.64).opacity(0.10)

    private static func adaptive(light: UIColor, dark: UIColor) -> Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? dark : light
        })
    }
}
