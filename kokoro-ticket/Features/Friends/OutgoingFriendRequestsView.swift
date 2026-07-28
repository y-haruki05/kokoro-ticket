import SwiftUI

struct OutgoingFriendRequestsView: View {
    let store: FriendStore

    var body: some View {
        ScrollView {
            if store.outgoingRequests.isEmpty {
                FriendEmptyStateView(
                    imageName: "cat_default",
                    title: "送信中の申請はありません。",
                    message: "フレンド申請を送ると、ここで確認できます。"
                )
                .padding(.horizontal, 20)
                .padding(.top, 36)
            } else {
                LazyVStack(spacing: 14) {
                    ForEach(store.outgoingRequests) { request in
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
                Text("送信中")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(AppColors.textPrimary)
            }
        }
        .toolbarBackground(AppColors.background, for: .navigationBar)
        .toolbarColorScheme(.light, for: .navigationBar)
        .friendErrorAlert(store: store)
    }

    private func requestCard(_ request: FriendRequest) -> some View {
        VStack(spacing: 12) {
            FriendProfileRow(profile: request.receiverProfile, store: store)

            HStack {
                Label(
                    request.createdAt.formatted(
                        Date.FormatStyle(date: .abbreviated, time: .shortened)
                            .locale(Locale(identifier: "ja_JP"))
                    ),
                    systemImage: "clock"
                )

                Spacer()

                Label("申請中", systemImage: "paperplane.fill")
                    .fontWeight(.bold)
                    .foregroundStyle(AppColors.primaryDark)
            }
            .font(.system(size: 11, weight: .medium, design: .rounded))
            .foregroundStyle(AppColors.textSecondary)
        }
        .padding(15)
        .background(AppColors.primarySoft.opacity(0.4))
        .clipShape(RoundedRectangle(cornerRadius: 23, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 23, style: .continuous)
                .stroke(AppColors.border.opacity(0.8), lineWidth: 1)
        }
    }
}

#if DEBUG
#Preview("送信あり") {
    NavigationStack {
        OutgoingFriendRequestsView(
            store: FriendStore(
                repository: InMemoryFriendRepository(),
                outgoingRequests: [FriendPreviewData.outgoingRequest]
            )
        )
    }
}
#endif
