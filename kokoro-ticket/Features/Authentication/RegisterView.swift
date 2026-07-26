import SwiftUI

struct RegisterView: View {
    let store: SessionStore

    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    @State private var password = ""
    @State private var passwordConfirmation = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 26) {
                VStack(spacing: 10) {
                    Text("アカウントを作る")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(AppColors.primary)

                    Text("こころチケットをはじめよう")
                        .font(.system(size: 15, design: .rounded))
                        .foregroundStyle(AppColors.textSecondary)
                }

                VStack(spacing: 18) {
                    AuthenticationFormField(
                        title: "メールアドレス",
                        placeholder: "example@example.com",
                        text: $email,
                        textContentType: .emailAddress
                    )

                    AuthenticationFormField(
                        title: "パスワード",
                        placeholder: "パスワードを入力",
                        text: $password,
                        isSecure: true,
                        textContentType: .newPassword
                    )

                    AuthenticationFormField(
                        title: "パスワード確認",
                        placeholder: "もう一度入力",
                        text: $passwordConfirmation,
                        isSecure: true,
                        textContentType: .newPassword
                    )
                }

                PrimaryActionButton(
                    title: "新規登録",
                    isLoading: store.isLoading
                ) {
                    Task {
                        await store.signUp(
                            email: email,
                            password: password,
                            passwordConfirmation: passwordConfirmation
                        )
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 32)
            .padding(.bottom, 32)
        }
        .background(AppColors.background)
        .navigationTitle("新規登録")
        .navigationBarTitleDisplayMode(.inline)
        .alert(
            "登録を確認してください",
            isPresented: registrationMessagePresented
        ) {
            Button("OK") {
                store.clearRegistrationMessage()
                dismiss()
            }
        } message: {
            Text(store.registrationMessage ?? "")
        }
    }

    private var registrationMessagePresented: Binding<Bool> {
        Binding(
            get: { store.registrationMessage != nil },
            set: { isPresented in
                if !isPresented {
                    store.clearRegistrationMessage()
                }
            }
        )
    }
}

#Preview {
    NavigationStack {
        RegisterView(store: SessionStore(repository: InMemoryAuthRepository()))
    }
}
