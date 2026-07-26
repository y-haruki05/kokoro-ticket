import SwiftUI

struct AuthenticationFormField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var isSecure = false
    var textContentType: UITextContentType?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(AppColors.textPrimary)

            Group {
                if isSecure {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                }
            }
            .textContentType(textContentType)
            .font(.system(size: 16, design: .rounded))
            .padding(.horizontal, 16)
            .frame(height: 54)
            .background(AppColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(AppColors.border, lineWidth: 1.5)
            }
        }
    }
}

#Preview {
    @Previewable @State var text = ""

    AuthenticationFormField(
        title: "メールアドレス",
        placeholder: "example@example.com",
        text: $text,
        textContentType: .emailAddress
    )
    .padding()
    .background(AppColors.background)
}
