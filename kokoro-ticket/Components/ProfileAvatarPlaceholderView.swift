import SwiftUI

struct ProfileAvatarPlaceholderView: View {
    var size: CGFloat = 96

    var body: some View {
        ZStack {
            Circle()
                .fill(AppColors.primarySoft)

            Image(systemName: "person.crop.circle")
                .font(.system(size: size * 0.48, weight: .medium))
                .foregroundStyle(AppColors.primary)
        }
        .frame(width: size, height: size)
        .overlay {
            Circle()
                .stroke(AppColors.border, lineWidth: 1.5)
        }
        .accessibilityLabel("アバター画像は未設定です")
    }
}

#Preview {
    ProfileAvatarPlaceholderView()
        .padding()
}
