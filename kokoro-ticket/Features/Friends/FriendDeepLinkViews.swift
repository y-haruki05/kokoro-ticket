import SwiftUI

struct FriendRequestDetailView: View {
    let requestID: UUID
    let store: FriendStore

    var body: some View {
        Group {
            if let request = store.incomingRequests.first(where: { $0.id == requestID }) {
                VStack(spacing: 24) {
                    FriendRemoteAvatarView(
                        store: store,
                        avatarKey: request.senderProfile.avatarKey,
                        size: 104
                    )
                    FriendProfileRow(profile: request.senderProfile, store: store)
                    HStack(spacing: 12) {
                        Button("拒否") { Task { await store.reject(request) } }
                            .buttonStyle(.bordered)
                        Button("承認") { Task { await store.accept(request) } }
                            .buttonStyle(.borderedProminent)
                            .tint(AppColors.primary)
                    }
                    .disabled(store.processingRequestIDs.contains(request.id))
                }
                .padding(24)
            } else {
                FriendEmptyStateView(
                    imageName: "cat_sad",
                    title: "対象の情報を表示できません",
                    message: "申請が処理または削除された可能性があります。"
                )
                .padding(24)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.background)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("フレンド申請")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(AppColors.textPrimary)
            }
        }
        .appNavigationStyle()
    }
}

struct FriendDetailView: View {
    let friendID: UUID
    let store: FriendStore

    var body: some View {
        Group {
            if let friend = store.friends.first(where: { $0.id == friendID }) {
                VStack(spacing: 14) {
                    FriendRemoteAvatarView(
                        store: store,
                        avatarKey: friend.avatarKey,
                        size: 112
                    )
                    Text(friend.displayName)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                    Text(friend.friendCode)
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(AppColors.primaryDark)
                    Label(
                        "つながった日 \(friend.friendshipCreatedAt.formatted(Date.FormatStyle(date: .abbreviated, time: .omitted).locale(Locale(identifier: "ja_JP"))))",
                        systemImage: "heart.fill"
                    )
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppColors.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(28)
                .background(AppColors.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .stroke(AppColors.border, lineWidth: 1.2)
                }
                .shadow(color: AppColors.shadow.opacity(0.5), radius: 10, y: 4)
                .padding(20)
            } else {
                FriendEmptyStateView(
                    imageName: "cat_sad",
                    title: "対象のフレンド情報を表示できません",
                    message: "情報が更新または削除された可能性があります。"
                )
                .padding(24)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.background)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("フレンド詳細")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(AppColors.textPrimary)
            }
        }
        .appNavigationStyle()
    }
}
