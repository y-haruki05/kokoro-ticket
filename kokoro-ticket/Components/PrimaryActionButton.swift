import SwiftUI

struct PrimaryActionButton: View {
    let title: String
    var isLoading = false
    var isDisabled = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Text(title)
                    .opacity(isLoading ? 0 : 1)

                if isLoading {
                    ProgressView()
                        .tint(.white)
                }
            }
            .accessibilityLabel(isLoading ? "\(title)、処理中" : title)
        }
        .buttonStyle(AppPrimaryButtonStyle())
        .disabled(isDisabled || isLoading)
        .opacity(isDisabled ? 0.55 : 1)
    }
}

#Preview {
    PrimaryActionButton(title: "ログイン", action: {})
        .padding()
}
