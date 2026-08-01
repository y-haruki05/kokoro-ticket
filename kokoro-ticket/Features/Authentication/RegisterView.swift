import SwiftUI

/// 新規登録の入力検証と、確認メール待ち画面への遷移を担当する画面
struct RegisterView: View {
    let store: SessionStore

    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    @State private var password = ""
    @State private var passwordConfirmation = ""
    @FocusState private var focusedField: AuthenticationInputField?

    var body: some View {
        Group {
            if let pendingEmail = store.pendingConfirmationEmail {
                EmailConfirmationPendingView(email: pendingEmail) {
                    store.clearPendingConfirmation()
                    dismiss()
                }
            } else {
                registrationForm
            }
        }
        .navigationBarBackButtonHidden(store.pendingConfirmationEmail != nil)
    }

    private var registrationForm: some View {
        ScrollView {
            VStack(spacing: 22) {
                header

                VStack(spacing: 18) {
                    AuthenticationFormField(
                        title: "メールアドレス",
                        placeholder: "example@example.com",
                        text: $email,
                        usesEmailKeyboard: true,
                        textContentType: .emailAddress,
                        focus: .email,
                        focusedField: $focusedField,
                        submitLabel: .next,
                        onSubmit: {
                            focusedField = .password
                        }
                    )

                    AuthenticationFormField(
                        title: "パスワード",
                        placeholder: "6文字以上で入力",
                        text: $password,
                        isSecure: true,
                        textContentType: .newPassword,
                        focus: .password,
                        focusedField: $focusedField,
                        submitLabel: .next,
                        onSubmit: {
                            focusedField = .passwordConfirmation
                        }
                    )

                    AuthenticationFormField(
                        title: "パスワード確認",
                        placeholder: "もう一度入力",
                        text: $passwordConfirmation,
                        isSecure: true,
                        textContentType: .newPassword,
                        focus: .passwordConfirmation,
                        focusedField: $focusedField,
                        submitLabel: .go,
                        onSubmit: signUp
                    )
                }
                .padding(20)
                .background(AppColors.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 26))
                .overlay {
                    RoundedRectangle(cornerRadius: 26)
                        .stroke(AppColors.border.opacity(0.85), lineWidth: 1)
                }
                .shadow(color: AppColors.shadow, radius: 12, y: 6)

                if let error = store.authError {
                    AuthenticationFeedbackView(
                        imageName: "cat_sad",
                        title: "登録内容を確認してね",
                        message: error.localizedDescription,
                        actionTitle: "閉じる",
                        action: store.clearError
                    )
                }

                PrimaryActionButton(
                    title: "新規登録",
                    isLoading: store.isLoading
                ) {
                    signUp()
                }

                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 5) {
                        Text("アカウントをお持ちの方は")
                            .foregroundStyle(AppColors.textSecondary)
                        Text("ログインへ戻る")
                            .foregroundStyle(AppColors.primaryDark)
                    }
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .frame(minHeight: 44)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 22)
            .padding(.top, 20)
            .padding(.bottom, 36)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(AppColors.background.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("閉じる") {
                    focusedField = nil
                }
                .fontWeight(.semibold)
            }
        }
    }

    private var header: some View {
        VStack(spacing: 9) {
            Image("cat_ticket")
                .resizable()
                .scaledToFit()
                .frame(width: 128, height: 102)
                .accessibilityHidden(true)

            Text("はじめまして！")
                .font(.system(.title, design: .rounded, weight: .bold))
                .foregroundStyle(AppColors.primaryDark)

            Text("こころを届ける準備をしよう")
                .font(.system(.body, design: .rounded, weight: .medium))
                .foregroundStyle(AppColors.textSecondary)
        }
    }

    private func signUp() {
        guard !store.isLoading else { return }
        focusedField = nil
        Task {
            await store.signUp(
                email: email,
                password: password,
                passwordConfirmation: passwordConfirmation
            )
            if store.pendingConfirmationEmail != nil {
                password = ""
                passwordConfirmation = ""
            }
        }
    }
}

#Preview("新規登録") {
    NavigationStack {
        RegisterView(
            store: SessionStore(
                repository: InMemoryAuthRepository(),
                isLoading: false
            )
        )
    }
}

#Preview("パスワード不一致") {
    NavigationStack {
        RegisterView(
            store: SessionStore(
                repository: InMemoryAuthRepository(),
                isLoading: false,
                authError: .passwordMismatch
            )
        )
    }
}

#Preview("メール確認待ち") {
    NavigationStack {
        RegisterView(
            store: SessionStore(
                repository: InMemoryAuthRepository(
                    signUpRequiresEmailConfirmation: true
                ),
                isLoading: false,
                pendingConfirmationEmail: "kokoro@example.com"
            )
        )
    }
}
