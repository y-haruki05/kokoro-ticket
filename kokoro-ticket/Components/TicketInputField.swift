import SwiftUI

enum TicketInputFocus: Hashable {
    case title
    case message
}

struct TicketInputField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var supportingText: String?
    var characterLimit: Int?
    var focusedField: FocusState<TicketInputFocus?>.Binding?
    var onSubmit: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: 11) {
            Text(title)
                .font(.system(.headline, design: .rounded, weight: .bold))
                .foregroundStyle(AppColors.textPrimary)

            inputField

            supportingLabel
        }
    }

    @ViewBuilder
    private var inputField: some View {
        if let focusedField {
            styledTextField
                .focused(focusedField, equals: .title)
        } else {
            styledTextField
        }
    }

    private var styledTextField: some View {
        TextField(placeholder, text: $text)
                .font(.system(.body, design: .rounded, weight: .medium))
                .foregroundStyle(AppColors.textPrimary)
                .submitLabel(.next)
                .onSubmit(onSubmit)
                .padding(.horizontal, 18)
                .frame(height: 60)
                .background(AppColors.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .overlay {
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(AppColors.border, lineWidth: 1.2)
                }
                .onChange(of: text) { _, newValue in
                    guard let characterLimit, newValue.count > characterLimit else { return }
                    text = String(newValue.prefix(characterLimit))
                }
    }

    @ViewBuilder
    private var supportingLabel: some View {
        if supportingText != nil || characterLimit != nil {
            HStack(alignment: .top, spacing: 8) {
                if let supportingText {
                    Text(supportingText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                if let characterLimit {
                    Text("\(text.count)/\(characterLimit)")
                        .monospacedDigit()
                }
            }
            .font(.system(.caption, design: .rounded, weight: .medium))
            .foregroundStyle(AppColors.textSecondary)
        }
    }
}

struct TicketMessageInputField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var supportingText: String?
    var characterLimit: Int?
    var focusedField: FocusState<TicketInputFocus?>.Binding?

    var body: some View {
        VStack(alignment: .leading, spacing: 11) {
            Text(title)
                .font(.system(.headline, design: .rounded, weight: .bold))
                .foregroundStyle(AppColors.textPrimary)

            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text(placeholder)
                        .font(.system(.body, design: .rounded, weight: .medium))
                        .foregroundStyle(AppColors.textSecondary.opacity(0.65))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 16)
                        .allowsHitTesting(false)
                }

                editor
            }
            .background(AppColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay {
                RoundedRectangle(cornerRadius: 20)
                    .stroke(AppColors.border, lineWidth: 1.2)
            }

            supportingLabel
        }
    }

    @ViewBuilder
    private var editor: some View {
        if let focusedField {
            styledEditor
                .focused(focusedField, equals: .message)
        } else {
            styledEditor
        }
    }

    private var styledEditor: some View {
        TextEditor(text: $text)
            .font(.system(.body, design: .rounded, weight: .medium))
            .foregroundStyle(AppColors.textPrimary)
            .scrollContentBackground(.hidden)
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
            .frame(minHeight: 148)
            .onChange(of: text) { _, newValue in
                guard let characterLimit, newValue.count > characterLimit else { return }
                text = String(newValue.prefix(characterLimit))
            }
    }

    @ViewBuilder
    private var supportingLabel: some View {
        if supportingText != nil || characterLimit != nil {
            HStack(alignment: .top, spacing: 8) {
                if let supportingText {
                    Text(supportingText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                if let characterLimit {
                    Text("\(text.count)/\(characterLimit)")
                        .monospacedDigit()
                }
            }
            .font(.system(.caption, design: .rounded, weight: .medium))
            .foregroundStyle(AppColors.textSecondary)
        }
    }
}

#Preview {
    @Previewable @State var title = ""
    @Previewable @State var message = ""

    VStack(spacing: 20) {
        TicketInputField(
            title: "チケット名",
            placeholder: "例：肩たたき券",
            text: $title,
            supportingText: "相手が使える内容を「○○券」の形で書いてみよう",
            characterLimit: 20
        )

        TicketMessageInputField(
            title: "ひとことメッセージ",
            placeholder: "例：疲れた日に使ってね。心を込めて肩をたたきます！",
            text: $message,
            supportingText: "このチケットの使い方や、相手へ伝えたい気持ちを書いてみよう",
            characterLimit: 100
        )
    }
    .padding()
    .background(AppColors.background)
}
