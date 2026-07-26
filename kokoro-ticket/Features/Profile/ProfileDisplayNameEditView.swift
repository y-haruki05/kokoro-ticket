import SwiftUI

struct ProfileDisplayNameEditView: View {
    let store: ProfileStore

    @Environment(\.dismiss) private var dismiss
    @State private var displayName: String

    init(store: ProfileStore) {
        self.store = store
        _displayName = State(initialValue: store.profile?.displayName ?? "")
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                AuthenticationFormField(
                    title: "表示名",
                    placeholder: "こころ",
                    text: $displayName,
                    textContentType: .name
                )
                .onChange(of: displayName) { _, newValue in
                    if newValue.count > ProfileStore.maximumDisplayNameLength {
                        displayName = String(
                            newValue.prefix(ProfileStore.maximumDisplayNameLength)
                        )
                    }
                }

                PrimaryActionButton(
                    title: "保存",
                    isLoading: store.isLoading,
                    isDisabled: normalizedDisplayName.isEmpty
                ) {
                    Task {
                        await store.updateDisplayName(displayName)
                        if store.error == nil {
                            dismiss()
                        }
                    }
                }

                Spacer()
            }
            .padding(24)
            .background(AppColors.background)
            .navigationTitle("表示名を変更")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var normalizedDisplayName: String {
        displayName.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
