import SwiftUI

struct LoginView: View {
    let store: SessionStore

    @State private var email = ""
    @State private var password = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    header

                    VStack(spacing: 18) {
                        AuthenticationFormField(
                            title: "メールアドレス",
                            placeholder: "example@example.com",
                            text: $email,
                            usesEmailKeyboard: true,
                            textContentType: .emailAddress
                        )

                        AuthenticationFormField(
                            title: "パスワード",
                            placeholder: "パスワードを入力",
                            text: $password,
                            isSecure: true,
                            textContentType: .password
                        )
                    }

                    PrimaryActionButton(
                        title: "ログイン",
                        isLoading: store.isLoading
                    ) {
                        Task {
                            await store.signIn(email: email, password: password)
                        }
                    }

                    NavigationLink {
                        RegisterView(store: store)
                    } label: {
                        Text("はじめての方はこちら")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(AppColors.primaryDark)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 60)
                .padding(.bottom, 32)
            }
            .background(AppColors.background)
        }
        .task {
            await store.restoreSession()
        }
    }

    private var header: some View {
        VStack(spacing: 12) {
            Text("こころチケット")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(AppColors.primary)

            Text("おかえりなさい")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(AppColors.textPrimary)

            Text("メールアドレスとパスワードでログインしてください")
                .font(.system(size: 14, design: .rounded))
                .foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center)
        }
    }
}

#Preview {
    LoginView(store: SessionStore(repository: InMemoryAuthRepository()))
}
