import SwiftUI

enum ProfileEditPresentation {
    case automatic
    case saving
    case success
    case failure
}

struct ProfileDisplayNameEditView: View {
    let store: ProfileStore
    var presentation: ProfileEditPresentation = .automatic

    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: AuthenticationInputField?
    @State private var displayName: String
    @State private var didSave = false

    init(
        store: ProfileStore,
        presentation: ProfileEditPresentation = .automatic
    ) {
        self.store = store
        self.presentation = presentation
        _displayName = State(initialValue: store.profile?.displayName ?? "")
        _didSave = State(initialValue: presentation == .success)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Image(feedbackImageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 116, height: 96)
                        .accessibilityHidden(true)

                    Text(feedbackTitle)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(AppColors.textPrimary)
                        .multilineTextAlignment(.center)

                    if !didSave {
                        AuthenticationFormField(
                            title: "表示名",
                            placeholder: "こころ",
                            text: $displayName,
                            textContentType: .name,
                            focus: .displayName,
                            focusedField: $focusedField,
                            submitLabel: .done,
                            onSubmit: save
                        )
                        .onChange(of: displayName) { _, newValue in
                            if newValue.count > ProfileStore.maximumDisplayNameLength {
                                displayName = String(
                                    newValue.prefix(ProfileStore.maximumDisplayNameLength)
                                )
                            }
                        }

                        Text("\(displayName.count)/\(ProfileStore.maximumDisplayNameLength)文字")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(AppColors.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .trailing)

                        if showsFailure {
                            HStack(spacing: 10) {
                                Image("cat_sad")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 46, height: 40)

                                Text(store.error?.localizedDescription
                                     ?? "表示名を保存できませんでした。もう一度お試しください。")
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                                    .foregroundStyle(AppColors.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(14)
                            .background(AppColors.pastelPink.opacity(0.45))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }

                        PrimaryActionButton(
                            title: "保存する",
                            isLoading: isSaving,
                            isDisabled: normalizedDisplayName.isEmpty
                        ) {
                            save()
                        }
                    }
                }
                .padding(24)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(AppColors.background.ignoresSafeArea())
            .navigationTitle("表示名を変更")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("閉じる") { dismiss() }
                        .foregroundStyle(AppColors.primaryDark)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("閉じる") { focusedField = nil }
                }
            }
        }
    }

    private var feedbackImageName: String {
        if didSave { return "cat_happy" }
        if showsFailure { return "cat_sad" }
        return "cat_default"
    }

    private var feedbackTitle: String {
        if didSave { return "保存しました！" }
        if showsFailure { return "うまく保存できませんでした" }
        return "どんな名前で呼ばれたい？"
    }

    private var isSaving: Bool {
        presentation == .saving
            || (presentation == .automatic && store.isLoading)
    }

    private var showsFailure: Bool {
        presentation == .failure
            || (presentation == .automatic && store.error != nil)
    }

    private var normalizedDisplayName: String {
        displayName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func save() {
        guard
            presentation == .automatic,
            !isSaving,
            !normalizedDisplayName.isEmpty
        else { return }

        focusedField = nil
        store.clearError()
        Task {
            await store.updateDisplayName(displayName)
            guard store.error == nil else { return }

            withAnimation(.easeInOut(duration: 0.2)) {
                didSave = true
            }
            try? await Task.sleep(for: .seconds(0.9))
            dismiss()
        }
    }
}

#Preview("通常") {
    ProfileDisplayNameEditView(store: previewProfileStore())
}

#Preview("保存中") {
    ProfileDisplayNameEditView(
        store: previewProfileStore(isLoading: true),
        presentation: .saving
    )
}

#Preview("保存成功") {
    ProfileDisplayNameEditView(
        store: previewProfileStore(),
        presentation: .success
    )
}

#Preview("保存失敗") {
    ProfileDisplayNameEditView(
        store: previewProfileStore(error: .profile(description: "通信状態を確認してください")),
        presentation: .failure
    )
}

@MainActor
private func previewProfileStore(
    isLoading: Bool = false,
    error: AppError? = nil
) -> ProfileStore {
    ProfileStore(
        repository: InMemoryProfileRepository(profile: .preview),
        profile: .preview,
        isLoading: isLoading,
        error: error
    )
}
