import SwiftUI

struct IncomingFriendRequestsView: View {
    let store: FriendStore

    var body: some View {
        ScrollView {
            if store.incomingRequests.isEmpty {
                FriendEmptyStateView(
                    imageName: "cat_happy",
                    title: "申請はありません。",
                    message: "新しい申請が届くと、ここに表示されます。"
                )
                .padding(.horizontal, 20)
                .padding(.top, 36)
            } else {
                LazyVStack(spacing: 14) {
                    ForEach(store.incomingRequests) { request in
                        requestCard(request)
                    }
                }
                .padding(20)
            }
        }
        .refreshable { await store.reload() }
        .background(AppColors.background)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("受信した申請")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(AppColors.textPrimary)
            }
        }
        .toolbarBackground(AppColors.background, for: .navigationBar)
        .toolbarColorScheme(.light, for: .navigationBar)
        .friendErrorAlert(store: store)
        .overlay(alignment: .bottom) {
            requestFeedback
        }
    }

    private func requestCard(_ request: FriendRequest) -> some View {
        VStack(spacing: 13) {
            FriendProfileRow(profile: request.senderProfile, store: store)

            HStack {
                Label(
                    request.createdAt.formatted(
                        Date.FormatStyle(date: .abbreviated, time: .shortened)
                            .locale(Locale(identifier: "ja_JP"))
                    ),
                    systemImage: "clock"
                )
                Spacer()
                Text("フレンド申請")
                    .fontWeight(.bold)
                    .foregroundStyle(AppColors.primaryDark)
            }
            .font(.system(size: 11, weight: .medium, design: .rounded))
            .foregroundStyle(AppColors.textSecondary)

            if store.processingRequestIDs.contains(request.id) {
                HStack(spacing: 9) {
                    ProgressView().tint(AppColors.primary)
                    Text("申請を処理しています")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(AppColors.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 48)
            } else {
                HStack(spacing: 12) {
                    Button {
                        Task { await store.reject(request) }
                    } label: {
                        actionLabel("拒否", primary: false)
                    }

                    Button {
                        Task { await store.accept(request) }
                    } label: {
                        actionLabel("承認", primary: true)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(15)
        .background(AppColors.primarySoft.opacity(0.4))
        .clipShape(RoundedRectangle(cornerRadius: 23, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 23, style: .continuous)
                .stroke(AppColors.border.opacity(0.8), lineWidth: 1)
        }
    }

    private func actionLabel(_ title: String, primary: Bool) -> some View {
        Text(title)
        .font(.system(size: 15, weight: .bold, design: .rounded))
        .foregroundStyle(primary ? .white : AppColors.primaryDark)
        .frame(maxWidth: .infinity)
        .frame(height: 48)
        .background(primary ? AppColors.primary : AppColors.cardBackground)
        .clipShape(Capsule())
        .overlay {
            Capsule().stroke(AppColors.border, lineWidth: primary ? 0 : 1.2)
        }
        .contentShape(Capsule())
    }

    @ViewBuilder
    private var requestFeedback: some View {
        if let message = store.requestMessage {
            HStack(spacing: 8) {
                Image("cat_happy")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 32, height: 32)
                Text(message)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
            }
            .foregroundStyle(AppColors.primaryDark)
            .padding(.horizontal, 16)
            .padding(.vertical, 9)
            .background(AppColors.cardBackground)
            .clipShape(Capsule())
            .overlay { Capsule().stroke(AppColors.border, lineWidth: 1) }
            .shadow(color: AppColors.shadow, radius: 7, y: 3)
            .padding(.bottom, 20)
            .task(id: message) {
                try? await Task.sleep(for: .seconds(2))
                store.clearMessage()
            }
        }
    }
}

#if DEBUG
#Preview("受信あり") {
    NavigationStack {
        IncomingFriendRequestsView(
            store: FriendStore(
                repository: InMemoryFriendRepository(),
                incomingRequests: [FriendPreviewData.incomingRequest]
            )
        )
    }
}

#Preview("受信0件") {
    NavigationStack {
        IncomingFriendRequestsView(
            store: FriendStore(repository: InMemoryFriendRepository())
        )
    }
}
#endif
