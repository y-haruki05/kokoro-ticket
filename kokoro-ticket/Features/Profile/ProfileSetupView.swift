import SwiftUI

struct ProfileSetupView: View {
    let store: ProfileStore

    @State private var displayName = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                VStack(spacing: 14) {
                    ProfileAvatarPlaceholderView()

                    Text("プロフィールを設定しよう")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(AppColors.primary)

                    Text("みんなに表示する名前を入力してください")
                        .font(.system(size: 15, design: .rounded))
                        .foregroundStyle(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                }

                AuthenticationFormField(
                    title: "表示名",
                    placeholder: "こころ",
                    text: $displayName,
                    textContentType: .name
                )
                .onChange(of: displayName) { _, newValue in
                    if newValue.count > ProfileStore.maximumDisplayNameLength {
                        displayName = String(
                            newValue.prefix(ProfileStore.maximumDisplayNameLength)
                        )
                    }
                }

                friendCodeInformation

                PrimaryActionButton(
                    title: "はじめる",
                    isLoading: store.isLoading,
                    isDisabled: normalizedDisplayName.isEmpty
                ) {
                    Task {
                        await store.createProfile(displayName: displayName)
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 44)
            .padding(.bottom, 32)
        }
        .background(AppColors.background)
        .profileErrorAlert(store: store)
    }

    private var friendCodeInformation: some View {
        VStack(spacing: 10) {
            Text("フレンドコード")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(AppColors.textPrimary)

            Text("保存時に自動で発行されます")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(AppColors.primaryDark)

            Text("フレンドコードは、家族やお友だちとつながるときに使います。")
                .font(.system(size: 13, design: .rounded))
                .foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(AppColors.primarySoft)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private var normalizedDisplayName: String {
        displayName.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

#Preview("プロフィール未設定") {
    ProfileSetupView(
        store: ProfileStore(
            repository: InMemoryProfileRepository(),
            isLoading: false
        )
    )
}

#Preview("保存中") {
    ProfileSetupView(
        store: ProfileStore(
            repository: InMemoryProfileRepository(),
            isLoading: true
        )
    )
}

#Preview("エラー") {
    ProfileSetupView(
        store: ProfileStore(
            repository: InMemoryProfileRepository(),
            isLoading: false,
            error: .friendCodeGenerationFailed
        )
    )
}
