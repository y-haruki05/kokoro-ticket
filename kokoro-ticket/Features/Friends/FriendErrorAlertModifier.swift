import SwiftUI

private struct FriendErrorAlertModifier: ViewModifier {
    let store: FriendStore

    func body(content: Content) -> some View {
        content.alert(
            "フレンド機能でエラーが発生しました",
            isPresented: Binding(
                get: { store.error != nil },
                set: { if !$0 { store.clearError() } }
            ),
            presenting: store.error
        ) { _ in
            Button("OK") { store.clearError() }
        } message: { error in
            Text(error.localizedDescription)
        }
    }
}

extension View {
    func friendErrorAlert(store: FriendStore) -> some View {
        modifier(FriendErrorAlertModifier(store: store))
    }
}
