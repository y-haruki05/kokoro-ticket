import SwiftUI

private struct ProfileErrorAlertModifier: ViewModifier {
    let store: ProfileStore

    func body(content: Content) -> some View {
        content.alert("プロフィールエラー", isPresented: errorPresented) {
            Button("OK") {
                store.clearError()
            }
        } message: {
            Text(store.error?.localizedDescription ?? "")
        }
    }

    private var errorPresented: Binding<Bool> {
        Binding(
            get: { store.error != nil },
            set: { isPresented in
                if !isPresented {
                    store.clearError()
                }
            }
        )
    }
}

extension View {
    func profileErrorAlert(store: ProfileStore) -> some View {
        modifier(ProfileErrorAlertModifier(store: store))
    }
}
