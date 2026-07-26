import SwiftUI

struct ProfileView: View {
    let email: String?
    let isLoading: Bool
    let onLogout: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(AppColors.primary)

                VStack(spacing: 8) {
                    Text("ログイン中")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(AppColors.textPrimary)

                    Text(email ?? "メールアドレス未設定")
                        .font(.system(size: 15, design: .rounded))
                        .foregroundStyle(AppColors.textSecondary)
                }

                Button(action: onLogout) {
                    Text(isLoading ? "ログアウト中…" : "ログアウト")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(AppColors.primaryDark)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(AppColors.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        .overlay {
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(AppColors.border, lineWidth: 1.5)
                        }
                        .contentShape(RoundedRectangle(cornerRadius: 18))
                }
                .buttonStyle(.plain)
                .disabled(isLoading)
            }
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppColors.background)
            .navigationTitle("マイページ")
        }
    }
}

#Preview {
    ProfileView(
        email: "preview@example.com",
        isLoading: false,
        onLogout: {}
    )
}
