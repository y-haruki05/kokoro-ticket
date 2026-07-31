import SwiftUI

struct ProfileSetupView: View {
    let store: ProfileStore
    var onCompletionStateChange: (Bool) -> Void = { _ in }

    @State private var displayName = ""
    @State private var isShowingCompletion: Bool
    @FocusState private var focusedField: AuthenticationInputField?

    init(
        store: ProfileStore,
        onCompletionStateChange: @escaping (Bool) -> Void = { _ in },
        initiallyShowsCompletion: Bool = false
    ) {
        self.store = store
        self.onCompletionStateChange = onCompletionStateChange
        _isShowingCompletion = State(initialValue: initiallyShowsCompletion)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                header

                AuthenticationFormField(
                    title: "表示名",
                    placeholder: "例：こころ",
                    text: $displayName,
                    textContentType: .name,
                    focus: .displayName,
                    focusedField: $focusedField,
                    submitLabel: .done,
                    onSubmit: createProfile
                )
                .onChange(of: displayName) { _, newValue in
                    if newValue.count > ProfileStore.maximumDisplayNameLength {
                        displayName = String(
                            newValue.prefix(ProfileStore.maximumDisplayNameLength)
                        )
                    }
                }

                friendCodeInformation

                if let error = store.error {
                    AuthenticationFeedbackView(
                        imageName: "cat_sad",
                        title: "プロフィールを保存できませんでした",
                        message: error.localizedDescription,
                        actionTitle: "閉じる",
                        action: store.clearError
                    )
                }

                PrimaryActionButton(
                    title: "はじめる",
                    isLoading: store.isLoading,
                    isDisabled: normalizedDisplayName.isEmpty
                ) {
                    createProfile()
                }
            }
            .padding(.horizontal, 22)
            .padding(.top, 28)
            .padding(.bottom, 36)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(AppColors.background.ignoresSafeArea())
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("閉じる") {
                    focusedField = nil
                }
                .fontWeight(.semibold)
            }
        }
        .overlay {
            if isShowingCompletion {
                completionView
                    .transition(.opacity)
            }
        }
    }

    private var header: some View {
        VStack(spacing: 10) {
            Image("cat_default")
                .resizable()
                .scaledToFit()
                .frame(width: 142, height: 116)
                .accessibilityHidden(true)

            Text("あなたのことを教えてね")
                .font(.system(.title2, design: .rounded, weight: .bold))
                .foregroundStyle(AppColors.primaryDark)
                .multilineTextAlignment(.center)

            Text("みんなに表示する名前を決めよう")
                .font(.system(.body, design: .rounded, weight: .medium))
                .foregroundStyle(AppColors.textSecondary)
        }
    }

    private var friendCodeInformation: some View {
        VStack(spacing: 9) {
            HStack(spacing: 8) {
                Image(systemName: "person.2.fill")
                    .foregroundStyle(AppColors.primary)
                Text("フレンドコード")
                    .font(.system(.headline, design: .rounded, weight: .bold))
                    .foregroundStyle(AppColors.textPrimary)
            }

            Text("プロフィール保存後に自動で発行されます")
                .font(.system(.subheadline, design: .rounded, weight: .bold))
                .foregroundStyle(AppColors.primaryDark)

            Text("家族やお友だちとつながるときに使う、あなた専用のコードです。")
                .font(.system(.caption, design: .rounded, weight: .medium))
                .foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(18)
        .background(AppColors.primarySoft)
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .overlay {
            RoundedRectangle(cornerRadius: 22)
                .stroke(AppColors.border.opacity(0.8), lineWidth: 1)
        }
    }

    private var completionView: some View {
        VStack(spacing: 14) {
            Image("cat_happy")
                .resizable()
                .scaledToFit()
                .frame(width: 148, height: 116)

            Text("準備ができました！")
                .font(.system(.title2, design: .rounded, weight: .bold))
                .foregroundStyle(AppColors.primaryDark)

            Text("こころチケットを楽しんでね")
                .font(.system(.body, design: .rounded, weight: .medium))
                .foregroundStyle(AppColors.textSecondary)
        }
        .padding(28)
        .frame(maxWidth: 320)
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 28))
        .overlay {
            RoundedRectangle(cornerRadius: 28)
                .stroke(AppColors.border, lineWidth: 1)
        }
        .shadow(color: AppColors.shadow, radius: 18, y: 8)
        .padding()
    }

    private var normalizedDisplayName: String {
        displayName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func createProfile() {
        guard !store.isLoading, !normalizedDisplayName.isEmpty else { return }
        focusedField = nil
        onCompletionStateChange(true)

        Task { @MainActor in
            await store.createProfile(displayName: displayName)

            guard store.isProfileCompleted else {
                onCompletionStateChange(false)
                return
            }

            withAnimation(.easeOut(duration: 0.2)) {
                isShowingCompletion = true
            }
            do {
                try await Task.sleep(for: .milliseconds(900))
            } catch {
                return
            }
            onCompletionStateChange(false)
        }
    }
}

#Preview("プロフィール初期設定") {
    ProfileSetupView(
        store: ProfileStore(
            repository: InMemoryProfileRepository(),
            isLoading: false
        )
    )
}

#Preview("プロフィール保存中") {
    ProfileSetupView(
        store: ProfileStore(
            repository: InMemoryProfileRepository(),
            isLoading: true
        )
    )
}

#Preview("プロフィール保存成功") {
    ProfileSetupView(
        store: ProfileStore(
            repository: InMemoryProfileRepository(),
            isLoading: false
        ),
        initiallyShowsCompletion: true
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

#Preview("Dark Mode") {
    ProfileSetupView(
        store: ProfileStore(
            repository: InMemoryProfileRepository(),
            isLoading: false
        )
    )
    .preferredColorScheme(.dark)
}
