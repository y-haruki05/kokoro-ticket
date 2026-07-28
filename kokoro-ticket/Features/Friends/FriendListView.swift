import SwiftUI

struct FriendListView: View {
    let store: FriendStore
    let profile: Profile
    let clipboard: any ClipboardWriting
    var currentAvatarData: Data? = nil
    var loadsRemoteData = true

    @State private var showsCopyMessage = false

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                friendCodeCard
                addFriendCard
                requestLinks
                friendContent
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 80)
        }
        .background(AppColors.background)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                friendNavigationTitle("フレンド")
            }
        }
        .toolbarBackground(AppColors.background, for: .navigationBar)
        .toolbarColorScheme(.light, for: .navigationBar)
        .task {
            guard loadsRemoteData else { return }
            await store.reload()
        }
        .refreshable {
            await store.reload()
        }
        .friendErrorAlert(store: store)
        .overlay(alignment: .bottom) {
            feedbackToast
        }
    }

    private func friendNavigationTitle(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 18, weight: .bold, design: .rounded))
            .foregroundStyle(AppColors.textPrimary)
    }

    private var friendCodeCard: some View {
        VStack(spacing: 13) {
            FriendAvatarView(
                imageData: currentAvatarData,
                size: 82
            )

            Text(profile.displayName)
                .font(.system(size: 21, weight: .bold, design: .rounded))
                .foregroundStyle(AppColors.textPrimary)
                .lineLimit(2)
                .multilineTextAlignment(.center)

            Text("あなたのフレンドコード")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(AppColors.textSecondary)

            Text(profile.friendCode)
                .font(.system(size: 25, weight: .bold, design: .rounded))
                .tracking(3)
                .foregroundStyle(AppColors.primaryDark)
                .textSelection(.enabled)

            Button {
                clipboard.copy(profile.friendCode)
                withAnimation(.easeInOut(duration: 0.2)) {
                    showsCopyMessage = true
                }
            } label: {
                Label("コードをコピー", systemImage: "doc.on.doc")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(AppColors.primaryDark)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(AppColors.primarySoft)
                    .clipShape(Capsule())
                    .contentShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .padding(22)
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(AppColors.border, lineWidth: 1.2)
        }
        .shadow(color: AppColors.shadow.opacity(0.55), radius: 10, y: 5)
    }

    private var addFriendCard: some View {
        NavigationLink {
            FriendSearchView(store: store, currentProfile: profile)
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "person.badge.plus")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(AppColors.primaryDark)
                    .frame(width: 52, height: 52)
                    .background(AppColors.primarySoft)
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text("フレンドを追加")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(AppColors.textPrimary)
                    Text("フレンドコードで大切な人を探せます")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(AppColors.textSecondary)
                }

                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(AppColors.primary)
            }
            .padding(16)
            .background(AppColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 21, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 21, style: .continuous)
                    .stroke(AppColors.border, lineWidth: 1)
            }
            .contentShape(RoundedRectangle(cornerRadius: 21, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var requestLinks: some View {
        HStack(spacing: 12) {
            NavigationLink {
                IncomingFriendRequestsView(store: store)
            } label: {
                requestLink(
                    title: "受信した申請",
                    count: store.incomingRequests.count,
                    icon: "tray.and.arrow.down.fill"
                )
            }

            NavigationLink {
                OutgoingFriendRequestsView(store: store)
            } label: {
                requestLink(
                    title: "送信中",
                    count: store.outgoingRequests.count,
                    icon: "paperplane.fill"
                )
            }
        }
        .buttonStyle(.plain)
    }

    private func requestLink(title: String, count: Int, icon: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
            Text(title)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Text("\(count)件")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
        }
        .foregroundStyle(AppColors.primaryDark)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(AppColors.primarySoft.opacity(0.65))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(AppColors.border.opacity(0.7), lineWidth: 1)
        }
    }

    @ViewBuilder
    private var friendContent: some View {
        if store.isLoading && store.friends.isEmpty {
            loadingView
        } else if store.error != nil && store.friends.isEmpty {
            errorView
        } else if store.friends.isEmpty {
            FriendEmptyStateView(
                imageName: "cat_default",
                title: "まだフレンドがいません。",
                message: "フレンドコードを交換して\n大切な人とつながりましょう。"
            )
        } else {
            friendList
        }
    }

    private var friendList: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("フレンド一覧")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(AppColors.textPrimary)
                Spacer()
                Text("\(store.friends.count)人")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(AppColors.textSecondary)
            }

            ForEach(store.friends) { friend in
                NavigationLink {
                    FriendDetailView(friendID: friend.id, store: store)
                } label: {
                    FriendProfileRow(
                        profile: FriendProfileSummary(
                            id: friend.id,
                            displayName: friend.displayName,
                            friendCode: friend.friendCode,
                            avatarKey: friend.avatarKey
                        ),
                        store: store,
                        date: friend.friendshipCreatedAt,
                        showsChevron: true
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView().tint(AppColors.primary)
            Text("フレンドを読み込んでいます")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 42)
    }

    private var errorView: some View {
        FriendEmptyStateView(
            imageName: "cat_sad",
            title: "フレンド情報を読み込めませんでした",
            message: "通信環境を確認して、もう一度お試しください。",
            buttonTitle: "もう一度読み込む"
        ) {
            Task { await store.reload() }
        }
    }

    @ViewBuilder
    private var feedbackToast: some View {
        if let message = store.requestMessage ?? (showsCopyMessage ? "コピーしました！" : nil) {
            HStack(spacing: 9) {
                Image("cat_happy")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 34, height: 34)
                Text(message)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
            }
            .foregroundStyle(AppColors.primaryDark)
            .padding(.horizontal, 16)
            .padding(.vertical, 9)
            .background(AppColors.cardBackground)
            .clipShape(Capsule())
            .overlay { Capsule().stroke(AppColors.border, lineWidth: 1) }
            .shadow(color: AppColors.shadow, radius: 8, y: 3)
            .padding(.bottom, 24)
            .transition(.opacity.combined(with: .scale(scale: 0.97)))
            .task(id: message) {
                try? await Task.sleep(for: .seconds(2))
                store.clearMessage()
                showsCopyMessage = false
            }
        }
    }
}

struct FriendProfileRow: View {
    let profile: FriendProfileSummary
    let store: FriendStore
    var date: Date? = nil
    var showsChevron = false

    var body: some View {
        HStack(spacing: 14) {
            FriendRemoteAvatarView(
                store: store,
                avatarKey: profile.avatarKey,
                size: 58
            )

            VStack(alignment: .leading, spacing: 5) {
                Text(profile.displayName)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(AppColors.textPrimary)
                    .lineLimit(2)

                Text(profile.friendCode)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .tracking(1)
                    .foregroundStyle(AppColors.primaryDark)

                if let date {
                    Text("つながった日 \(date.formatted(Date.FormatStyle(date: .abbreviated, time: .omitted).locale(Locale(identifier: "ja_JP"))))")
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(AppColors.textSecondary)
                }
            }

            Spacer(minLength: 8)

            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(AppColors.primary)
            }
        }
        .padding(15)
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(AppColors.border.opacity(0.85), lineWidth: 1)
        }
        .shadow(color: AppColors.shadow.opacity(0.42), radius: 7, y: 3)
        .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

struct FriendEmptyStateView: View {
    let imageName: String
    let title: String
    let message: String
    var buttonTitle: String? = nil
    var action: () -> Void = {}

    var body: some View {
        VStack(spacing: 12) {
            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 112, height: 112)
            Text(title)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(AppColors.textPrimary)
                .multilineTextAlignment(.center)
            Text(message)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(3)

            if let buttonTitle {
                Button(buttonTitle, action: action)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .frame(height: 46)
                    .background(AppColors.primary)
                    .clipShape(Capsule())
                    .buttonStyle(.plain)
                    .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }
}

#if DEBUG
#Preview("フレンド0人") {
    NavigationStack {
        FriendListView(
            store: FriendStore(repository: InMemoryFriendRepository()),
            profile: .preview,
            clipboard: PreviewClipboardService(),
            loadsRemoteData: false
        )
    }
}

#Preview("フレンドあり") {
    NavigationStack {
        FriendListView(
            store: FriendStore(
                repository: InMemoryFriendRepository(),
                friends: FriendPreviewData.friends
            ),
            profile: .preview,
            clipboard: PreviewClipboardService(),
            loadsRemoteData: false
        )
    }
}

#Preview("受信・送信あり") {
    NavigationStack {
        FriendListView(
            store: FriendStore(
                repository: InMemoryFriendRepository(),
                friends: [FriendPreviewData.friend],
                incomingRequests: [FriendPreviewData.incomingRequest],
                outgoingRequests: [FriendPreviewData.outgoingRequest]
            ),
            profile: .preview,
            clipboard: PreviewClipboardService(),
            loadsRemoteData: false
        )
    }
}

#Preview("Loading") {
    NavigationStack {
        FriendListView(
            store: FriendStore(
                repository: InMemoryFriendRepository(),
                isLoading: true
            ),
            profile: .preview,
            clipboard: PreviewClipboardService(),
            loadsRemoteData: false
        )
    }
}

#Preview("Error") {
    NavigationStack {
        FriendListView(
            store: FriendStore(
                repository: InMemoryFriendRepository(),
                error: .network(description: "通信環境を確認してください")
            ),
            profile: .preview,
            clipboard: PreviewClipboardService(),
            loadsRemoteData: false
        )
    }
}

#Preview("Dark Mode") {
    NavigationStack {
        FriendListView(
            store: FriendStore(
                repository: InMemoryFriendRepository(),
                friends: FriendPreviewData.friends
            ),
            profile: .preview,
            clipboard: PreviewClipboardService(),
            loadsRemoteData: false
        )
    }
    .preferredColorScheme(.dark)
}

#Preview("iPhone SE") {
    NavigationStack {
        FriendListView(
            store: FriendStore(
                repository: InMemoryFriendRepository(),
                friends: FriendPreviewData.friends
            ),
            profile: .preview,
            clipboard: PreviewClipboardService(),
            loadsRemoteData: false
        )
    }
    .frame(width: 375, height: 667)
}
#endif
