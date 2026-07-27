import SwiftUI

struct PushPermissionView: View {
    let store: PushNotificationStore
    let onLater: () -> Void

    var body: some View {
        VStack(spacing: 22) {
            Image(systemName: "bell.badge")
                .font(.system(size: 44))
                .foregroundStyle(AppColors.primary)
            Text("大切なお知らせを受け取ろう")
                .font(.system(size: 23, weight: .bold, design: .rounded))
            Text("フレンドからチケットが届いた時や、チケットが使われた時にお知らせします。")
                .font(.system(size: 16, design: .rounded))
                .foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center)
            if store.authorizationStatus == .denied {
                Button("設定を開く") { store.openSettings() }
                    .buttonStyle(.borderedProminent).tint(AppColors.primary)
            } else {
                Button("通知を許可する") {
                    Task { await store.requestAuthorization() }
                }
                .buttonStyle(.borderedProminent).tint(AppColors.primary)
                .disabled(store.isRequestingAuthorization)
            }
            Button("あとで", action: onLater)
                .foregroundStyle(AppColors.textSecondary)
        }
        .padding(28)
        .background(AppColors.background)
    }
}

#Preview("未決定") {
    PushPermissionView(
        store: PushNotificationStore(
            repository: InMemoryDeviceTokenRepository(),
            environment: "sandbox"
        ),
        onLater: {}
    )
}
