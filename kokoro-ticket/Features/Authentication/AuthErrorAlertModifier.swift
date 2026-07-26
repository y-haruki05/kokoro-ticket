import SwiftUI

private struct AuthErrorAlertModifier: ViewModifier {
    let store: SessionStore

    func body(content: Content) -> some View {
        content.alert("認証エラー", isPresented: errorPresented) {
            Button("OK") {
                store.clearError()
            }
        } message: {
            Text(store.authError?.localizedDescription ?? "")
        }
    }

    private var errorPresented: Binding<Bool> {
        Binding(
            get: { store.authError != nil },
            set: { isPresented in
                if !isPresented {
                    store.clearError()
                }
            }
        )
    }
}

extension View {
    func authErrorAlert(store: SessionStore) -> some View {
        modifier(AuthErrorAlertModifier(store: store))
    }
}
