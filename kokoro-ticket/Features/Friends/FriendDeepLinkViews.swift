import SwiftUI

struct FriendRequestDetailView: View {
    let requestID: UUID
    let store: FriendStore

    var body: some View {
        Group {
            if let request = store.incomingRequests.first(where: { $0.id == requestID }) {
                VStack(spacing: 24) {
                    ProfileAvatarPlaceholderView()
                    Text(request.senderProfile.displayName)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                    Text(request.senderProfile.friendCode)
                        .foregroundStyle(AppColors.textSecondary)
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
                ContentUnavailableView(
                    "対象の情報を表示できません",
                    systemImage: "person.crop.circle.badge.questionmark",
                    description: Text("申請が処理または削除された可能性があります。")
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.background)
        .navigationTitle("フレンド申請")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct FriendDetailView: View {
    let friendID: UUID
    let store: FriendStore

    var body: some View {
        Group {
            if let friend = store.friends.first(where: { $0.id == friendID }) {
                VStack(spacing: 18) {
                    ProfileAvatarPlaceholderView()
                    Text(friend.displayName)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                    Text(friend.friendCode)
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(AppColors.primaryDark)
                }
                .padding(24)
            } else {
                ContentUnavailableView(
                    "対象のフレンド情報を表示できません",
                    systemImage: "person.slash",
                    description: Text("情報が更新または削除された可能性があります。")
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.background)
        .navigationTitle("フレンド詳細")
        .navigationBarTitleDisplayMode(.inline)
    }
}
