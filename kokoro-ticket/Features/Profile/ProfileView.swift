import SwiftUI

@MainActor
struct ProfileView: View {
    let store: ProfileStore
    let friendStore: FriendStore
    let email: String?
    let isAuthLoading: Bool
    let onLogout: () -> Void
    @Binding private var deepLink: AppDeepLink?

    private let clipboard: any ClipboardWriting

    @State private var isShowingNameEditor = false
    @State private var showsCopyMessage = false

    init(
        store: ProfileStore,
        friendStore: FriendStore,
        email: String?,
        isAuthLoading: Bool,
        clipboard: any ClipboardWriting,
        deepLink: Binding<AppDeepLink?> = .constant(nil),
        onLogout: @escaping () -> Void
    ) {
        self.store = store
        self.friendStore = friendStore
        self.email = email
        self.isAuthLoading = isAuthLoading
        self.clipboard = clipboard
        _deepLink = deepLink
        self.onLogout = onLogout
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                if let profile = store.profile {
                    VStack(spacing: 24) {
                        ProfileAvatarPlaceholderView()

                        profileCard(profile)
                        NavigationLink {
                            FriendListView(
                                store: friendStore,
                                profile: profile,
                                clipboard: clipboard
                            )
                        } label: {
                            HStack(spacing: 14) {
                                Image(systemName: "person.2.fill")
                                    .foregroundStyle(AppColors.primary)
                                    .frame(width: 42, height: 42)
                                    .background(AppColors.primarySoft)
                                    .clipShape(Circle())
                                VStack(alignment: .leading, spacing: 3) {
                                    Text("フレンド")
                                        .font(.system(size: 17, weight: .bold, design: .rounded))
                                        .foregroundStyle(AppColors.textPrimary)
                                    Text("検索・申請・フレンド一覧")
                                        .font(.system(size: 13, design: .rounded))
                                        .foregroundStyle(AppColors.textSecondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(AppColors.textSecondary)
                            }
                            .padding(18)
                            .background(AppColors.cardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                            .contentShape(RoundedRectangle(cornerRadius: 18))
                        }
                        .buttonStyle(.plain)
                        accountCard
                        logoutButton
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 28)
                    .padding(.bottom, 110)
                }
            }
            .background(AppColors.background)
            .navigationTitle("マイページ")
            .sheet(isPresented: $isShowingNameEditor) {
                ProfileDisplayNameEditView(store: store)
                    .presentationDetents([.medium])
            }
            .overlay(alignment: .bottom) {
                if showsCopyMessage {
                    Text("フレンドコードをコピーしました")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 12)
                        .background(AppColors.primaryDark)
                        .clipShape(Capsule())
                        .padding(.bottom, 94)
                        .transition(.opacity)
                }
            }
        }
        .navigationDestination(
            isPresented: Binding(
                get: { deepLink != nil },
                set: { if !$0 { deepLink = nil } }
            )
        ) {
            switch deepLink {
            case let .incomingFriendRequest(id):
                FriendRequestDetailView(requestID: id, store: friendStore)
            case let .friend(id):
                FriendDetailView(friendID: id, store: friendStore)
            default:
                ContentUnavailableView(
                    "対象の情報を表示できません",
                    systemImage: "exclamationmark.triangle"
                )
            }
        }
        .profileErrorAlert(store: store)
    }

    private func profileCard(_ profile: Profile) -> some View {
        VStack(spacing: 18) {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text("表示名")
                        .font(.system(size: 13, design: .rounded))
                        .foregroundStyle(AppColors.textSecondary)

                    Text(profile.displayName)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(AppColors.textPrimary)
                }

                Spacer()

                Button("変更") {
                    isShowingNameEditor = true
                }
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(AppColors.primaryDark)
            }

            Divider()

            VStack(spacing: 10) {
                Text("フレンドコード")
                    .font(.system(size: 13, design: .rounded))
                    .foregroundStyle(AppColors.textSecondary)

                Text(profile.friendCode)
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .tracking(3)
                    .foregroundStyle(AppColors.primaryDark)
                    .textSelection(.enabled)

                Button {
                    copyFriendCode(profile.friendCode)
                } label: {
                    Label("コードをコピー", systemImage: "doc.on.doc")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(AppColors.primaryDark)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(AppColors.primarySoft)
                        .clipShape(RoundedRectangle(cornerRadius: 15))
                        .contentShape(RoundedRectangle(cornerRadius: 15))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(20)
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .stroke(AppColors.border, lineWidth: 1.5)
        }
        .shadow(color: AppColors.shadow, radius: 10, y: 4)
    }

    private var accountCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("ログイン中のメールアドレス")
                .font(.system(size: 13, design: .rounded))
                .foregroundStyle(AppColors.textSecondary)

            Text(email ?? "メールアドレス未設定")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(AppColors.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private var logoutButton: some View {
        Button(action: onLogout) {
            Text(isAuthLoading ? "ログアウト中…" : "ログアウト")
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(AppColors.primaryDark)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(AppColors.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .overlay {
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(AppColors.border, lineWidth: 1.5)
                }
                .contentShape(RoundedRectangle(cornerRadius: 18))
        }
        .buttonStyle(.plain)
        .disabled(isAuthLoading)
    }

    private func copyFriendCode(_ friendCode: String) {
        clipboard.copy(friendCode)

        withAnimation(.easeInOut(duration: 0.2)) {
            showsCopyMessage = true
        }

        Task {
            try? await Task.sleep(for: .seconds(2))
            withAnimation(.easeInOut(duration: 0.2)) {
                showsCopyMessage = false
            }
        }
    }
}

#Preview("マイページ") {
    let profile = Profile.preview

    ProfileView(
        store: ProfileStore(
            repository: InMemoryProfileRepository(profile: profile),
            profile: profile,
            isLoading: false
        ),
        friendStore: FriendStore(repository: InMemoryFriendRepository()),
        email: "preview@example.com",
        isAuthLoading: false,
        clipboard: PreviewClipboardService(),
        onLogout: {}
    )
}
