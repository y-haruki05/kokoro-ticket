import SwiftUI

struct FriendListView: View {
    let store: FriendStore
    let profile: Profile
    let clipboard: any ClipboardWriting

    @State private var showsCopyMessage = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                friendCodeCard
                requestLinks

                if store.isLoading && store.friends.isEmpty {
                    ProgressView().tint(AppColors.primary).padding(.top, 40)
                } else if store.friends.isEmpty {
                    emptyView
                } else {
                    friendList
                }
            }
            .padding(20)
            .padding(.bottom, 80)
        }
        .background(AppColors.background)
        .navigationTitle("フレンド")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    FriendSearchView(store: store)
                } label: {
                    Image(systemName: "person.badge.plus")
                }
                .accessibilityLabel("フレンドを追加")
            }
        }
        .task { await store.reload() }
        .refreshable { await store.reload() }
        .friendErrorAlert(store: store)
        .overlay(alignment: .bottom) {
            if let message = store.requestMessage ?? (showsCopyMessage ? "フレンドコードをコピーしました" : nil) {
                Text(message)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .background(AppColors.primaryDark)
                    .clipShape(Capsule())
                    .padding(.bottom, 24)
                    .transition(.opacity)
                    .task(id: message) {
                        try? await Task.sleep(for: .seconds(2))
                        store.clearMessage()
                        showsCopyMessage = false
                    }
            }
        }
    }

    private var friendCodeCard: some View {
        VStack(spacing: 12) {
            Text("あなたのフレンドコード")
                .font(.system(size: 14, design: .rounded))
                .foregroundStyle(AppColors.textSecondary)
            Text(profile.friendCode)
                .font(.system(size: 25, weight: .bold, design: .rounded))
                .tracking(3)
                .foregroundStyle(AppColors.primaryDark)
            HStack(spacing: 12) {
                Button {
                    clipboard.copy(profile.friendCode)
                    withAnimation(.easeInOut(duration: 0.2)) { showsCopyMessage = true }
                } label: {
                    Label("コピー", systemImage: "doc.on.doc")
                        .frame(maxWidth: .infinity).frame(height: 48)
                }
                NavigationLink {
                    FriendSearchView(store: store)
                } label: {
                    Label("フレンドを追加", systemImage: "plus")
                        .frame(maxWidth: .infinity).frame(height: 48)
                }
            }
            .font(.system(size: 14, weight: .bold, design: .rounded))
            .foregroundStyle(AppColors.primaryDark)
            .buttonStyle(.plain)
        }
        .padding(20)
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay { RoundedRectangle(cornerRadius: 20).stroke(AppColors.border, lineWidth: 1.5) }
    }

    private var requestLinks: some View {
        HStack(spacing: 12) {
            NavigationLink {
                IncomingFriendRequestsView(store: store)
            } label: {
                requestLink(
                    title: "受信申請",
                    count: store.incomingRequests.count,
                    icon: "tray.and.arrow.down"
                )
            }
            NavigationLink {
                OutgoingFriendRequestsView(store: store)
            } label: {
                requestLink(
                    title: "送信中",
                    count: store.outgoingRequests.count,
                    icon: "paperplane"
                )
            }
        }
        .buttonStyle(.plain)
    }

    private func requestLink(title: String, count: Int, icon: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon).font(.title3)
            Text(title).font(.system(size: 15, weight: .bold, design: .rounded))
            Text("\(count)件").font(.system(size: 13, design: .rounded))
        }
        .foregroundStyle(AppColors.primaryDark)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(AppColors.primarySoft)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private var friendList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("フレンド一覧")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(AppColors.textPrimary)
            ForEach(store.friends) { friend in
                FriendProfileRow(
                    profile: FriendProfileSummary(
                        id: friend.id,
                        displayName: friend.displayName,
                        friendCode: friend.friendCode,
                        avatarKey: friend.avatarKey
                    )
                )
            }
        }
    }

    private var emptyView: some View {
        VStack(spacing: 14) {
            ProfileAvatarPlaceholderView()
            Text("まだフレンドがいません")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(AppColors.textPrimary)
            Text("フレンドコードで大切な人を追加しましょう")
                .font(.system(size: 14, design: .rounded))
                .foregroundStyle(AppColors.textSecondary)
        }
        .padding(.top, 28)
    }
}

#Preview("フレンド0人") {
    NavigationStack {
        FriendListView(
            store: FriendStore(repository: InMemoryFriendRepository()),
            profile: .preview,
            clipboard: PreviewClipboardService()
        )
    }
}

#Preview("フレンドあり・申請あり") {
    NavigationStack {
        FriendListView(
            store: FriendStore(
                repository: InMemoryFriendRepository(),
                friends: [FriendPreviewData.friend],
                incomingRequests: [FriendPreviewData.incomingRequest],
                outgoingRequests: [FriendPreviewData.outgoingRequest]
            ),
            profile: .preview,
            clipboard: PreviewClipboardService()
        )
    }
}

#Preview("読込中") {
    NavigationStack {
        FriendListView(
            store: FriendStore(
                repository: InMemoryFriendRepository(),
                isLoading: true
            ),
            profile: .preview,
            clipboard: PreviewClipboardService()
        )
    }
}

struct FriendProfileRow: View {
    let profile: FriendProfileSummary

    var body: some View {
        HStack(spacing: 14) {
            ProfileAvatarPlaceholderView()
                .scaleEffect(0.65)
                .frame(width: 54, height: 54)
            VStack(alignment: .leading, spacing: 4) {
                Text(profile.displayName)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(AppColors.textPrimary)
                Text(profile.friendCode)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .tracking(1)
                    .foregroundStyle(AppColors.textSecondary)
            }
            Spacer()
        }
        .padding(16)
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay { RoundedRectangle(cornerRadius: 18).stroke(AppColors.border, lineWidth: 1) }
    }
}
