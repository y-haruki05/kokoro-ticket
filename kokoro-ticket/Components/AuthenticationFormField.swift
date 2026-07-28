import SwiftUI

enum AuthenticationInputField: Hashable {
    case email
    case password
    case passwordConfirmation
    case displayName
}

struct AuthenticationFormField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var isSecure = false
    var usesEmailKeyboard = false
    var textContentType: UITextContentType?
    var focus: AuthenticationInputField?
    var focusedField: FocusState<AuthenticationInputField?>.Binding?
    var submitLabel: SubmitLabel = .done
    var onSubmit: () -> Void = {}

    @State private var isSecureTextVisible = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(.subheadline, design: .rounded, weight: .bold))
                .foregroundStyle(AppColors.textPrimary)

            HStack(spacing: 10) {
                input

                if isSecure {
                    Button {
                        isSecureTextVisible.toggle()
                    } label: {
                        Image(systemName: isSecureTextVisible ? "eye.slash" : "eye")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(AppColors.textSecondary)
                            .frame(width: 36, height: 44)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(
                        isSecureTextVisible ? "パスワードを隠す" : "パスワードを表示"
                    )
                }
            }
            .padding(.horizontal, 16)
            .frame(minHeight: 58)
            .background(AppColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay {
                RoundedRectangle(cornerRadius: 18)
                    .stroke(AppColors.border, lineWidth: 1.2)
            }
            .shadow(color: AppColors.shadow.opacity(0.7), radius: 7, y: 3)
        }
    }

    @ViewBuilder
    private var input: some View {
        if isSecure && !isSecureTextVisible {
            configured(
                SecureField(placeholder, text: $text)
            )
        } else {
            configured(
                TextField(placeholder, text: $text)
            )
        }
    }

    @ViewBuilder
    private func configured<Field: View>(_ field: Field) -> some View {
        let base = field
            .textContentType(textContentType)
            .textInputAutocapitalization(
                usesEmailKeyboard || isSecure ? .never : .sentences
            )
            .keyboardType(usesEmailKeyboard ? .emailAddress : .default)
            .autocorrectionDisabled(usesEmailKeyboard || isSecure)
            .font(.system(.body, design: .rounded, weight: .medium))
            .foregroundStyle(AppColors.textPrimary)
            .submitLabel(submitLabel)
            .onSubmit(onSubmit)

        if let focusedField, let focus {
            base.focused(focusedField, equals: focus)
        } else {
            base
        }
    }
}

#Preview {
    @Previewable @State var text = ""

    AuthenticationFormField(
        title: "メールアドレス",
        placeholder: "example@example.com",
        text: $text,
        usesEmailKeyboard: true,
        textContentType: .emailAddress
    )
    .padding()
    .background(AppColors.background)
}
