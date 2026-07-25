import SwiftUI

struct TicketInputField: View {
    let title: String
    let placeholder: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            Text(title)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(AppColors.textPrimary)

            TextField(placeholder, text: $text)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundStyle(AppColors.textPrimary)
                .padding(.horizontal, 16)
                .frame(height: 54)
                .background(AppColors.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 17))
                .overlay {
                    RoundedRectangle(cornerRadius: 17)
                        .stroke(AppColors.border, lineWidth: 1.2)
                }
        }
    }
}

struct TicketMessageInputField: View {
    let title: String
    let placeholder: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            Text(title)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(AppColors.textPrimary)

            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text(placeholder)
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(AppColors.textSecondary.opacity(0.65))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 16)
                        .allowsHitTesting(false)
                }

                TextEditor(text: $text)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(AppColors.textPrimary)
                    .scrollContentBackground(.hidden)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 8)
                    .frame(minHeight: 124)
            }
            .background(AppColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 17))
            .overlay {
                RoundedRectangle(cornerRadius: 17)
                    .stroke(AppColors.border, lineWidth: 1.2)
            }
        }
    }
}

#Preview {
    @Previewable @State var title = ""
    @Previewable @State var message = ""

    VStack(spacing: 20) {
        TicketInputField(
            title: "チケット名",
            placeholder: "肩たたき券",
            text: $title
        )

        TicketMessageInputField(
            title: "メッセージ",
            placeholder: "ありがとうの気持ちを書こう",
            text: $message
        )
    }
    .padding()
    .background(AppColors.background)
}
