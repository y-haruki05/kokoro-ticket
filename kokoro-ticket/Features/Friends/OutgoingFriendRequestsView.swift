import SwiftUI

struct OutgoingFriendRequestsView: View {
    let store: FriendStore

    var body: some View {
        Group {
            if store.outgoingRequests.isEmpty {
                ContentUnavailableView(
                    "送信中の申請はありません",
                    systemImage: "paperplane",
                    description: Text("送った申請がここに表示されます")
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 14) {
                        ForEach(store.outgoingRequests) { request in
                            VStack(spacing: 12) {
                                FriendProfileRow(profile: request.receiverProfile)
                                HStack {
                                    Text(request.createdAt.formatted(date: .abbreviated, time: .shortened))
                                    Spacer()
                                    Text("申請中")
                                        .fontWeight(.bold)
                                        .foregroundStyle(AppColors.primaryDark)
                                }
                                .font(.system(size: 12, design: .rounded))
                                .foregroundStyle(AppColors.textSecondary)
                            }
                            .padding(16)
                            .background(AppColors.cardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .shadow(color: AppColors.shadow, radius: 8, y: 3)
                        }
                    }
                    .padding(20)
                }
            }
        }
        .background(AppColors.background)
        .navigationTitle("送信中の申請")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview("送信中申請あり") {
    NavigationStack {
        OutgoingFriendRequestsView(
            store: FriendStore(
                repository: InMemoryFriendRepository(),
                outgoingRequests: [FriendPreviewData.outgoingRequest]
            )
        )
    }
}
