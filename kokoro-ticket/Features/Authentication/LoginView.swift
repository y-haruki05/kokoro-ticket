import SwiftUI

struct LoginView: View {
    let store: SessionStore

    @State private var email = ""
    @State private var password = ""
    @FocusState private var focusedField: AuthenticationInputField?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
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
                            placeholder: "パスワードを入力",
                            text: $password,
                            isSecure: true,
                            textContentType: .password,
                            focus: .password,
                            focusedField: $focusedField,
                            submitLabel: .go,
                            onSubmit: signIn
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
                            title: "うまくログインできませんでした",
                            message: error.localizedDescription,
                            actionTitle: "閉じる",
                            action: store.clearError
                        )
                    }

                    PrimaryActionButton(
                        title: "ログイン",
                        isLoading: store.isLoading
                    ) {
                        signIn()
                    }

                    NavigationLink {
                        RegisterView(store: store)
                    } label: {
                        HStack(spacing: 5) {
                            Text("はじめての方は")
                                .foregroundStyle(AppColors.textSecondary)
                            Text("新規登録")
                                .foregroundStyle(AppColors.primaryDark)
                        }
                        .font(.system(.subheadline, design: .rounded, weight: .bold))
                        .frame(minHeight: 44)
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
        }
    }

    private var header: some View {
        VStack(spacing: 10) {
            Image("cat_welcome")
                .resizable()
                .scaledToFit()
                .frame(width: 132, height: 108)
                .accessibilityHidden(true)

            Text("おかえりなさい")
                .font(.system(.title, design: .rounded, weight: .bold))
                .foregroundStyle(AppColors.primaryDark)

            Text("こころチケットへログイン")
                .font(.system(.body, design: .rounded, weight: .medium))
                .foregroundStyle(AppColors.textSecondary)
        }
    }

    private func signIn() {
        guard !store.isLoading else { return }
        focusedField = nil
        Task {
            await store.signIn(email: email, password: password)
        }
    }
}

#Preview("未ログイン") {
    LoginView(
        store: SessionStore(
            repository: InMemoryAuthRepository(),
            isLoading: false
        )
    )
}

#Preview("入力中") {
    LoginView(
        store: SessionStore(
            repository: InMemoryAuthRepository(),
            isLoading: false
        )
    )
}

#Preview("ログインエラー") {
    LoginView(
        store: SessionStore(
            repository: InMemoryAuthRepository(),
            isLoading: false,
            authError: .authentication(
                description: "メールアドレスまたはパスワードを確認してください。"
            )
        )
    )
}

#Preview("Dark Mode") {
    LoginView(
        store: SessionStore(
            repository: InMemoryAuthRepository(),
            isLoading: false
        )
    )
    .preferredColorScheme(.dark)
}

#Preview("iPhone SE相当", traits: .fixedLayout(width: 375, height: 667)) {
    LoginView(
        store: SessionStore(
            repository: InMemoryAuthRepository(),
            isLoading: false
        )
    )
}
