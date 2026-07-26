import SwiftUI

struct IncomingFriendRequestsView: View {
    let store: FriendStore

    var body: some View {
        Group {
            if store.incomingRequests.isEmpty {
                ContentUnavailableView(
                    "受信した申請はありません",
                    systemImage: "tray",
                    description: Text("新しい申請が届くとここに表示されます")
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 14) {
                        ForEach(store.incomingRequests) { request in
                            requestCard(request)
                        }
                    }
                    .padding(20)
                }
            }
        }
        .background(AppColors.background)
        .navigationTitle("受信申請")
        .navigationBarTitleDisplayMode(.inline)
        .friendErrorAlert(store: store)
    }

    private func requestCard(_ request: FriendRequest) -> some View {
        VStack(spacing: 14) {
            FriendProfileRow(profile: request.senderProfile)
            Text(request.createdAt.formatted(date: .abbreviated, time: .shortened))
                .font(.system(size: 12, design: .rounded))
                .foregroundStyle(AppColors.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
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
            .disabled(store.processingRequestIDs.contains(request.id))
        }
        .padding(16)
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: AppColors.shadow, radius: 8, y: 3)
    }

    private func actionLabel(_ title: String, primary: Bool) -> some View {
        Text(title)
            .font(.system(size: 15, weight: .bold, design: .rounded))
            .foregroundStyle(primary ? .white : AppColors.primaryDark)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(primary ? AppColors.primary : AppColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay { RoundedRectangle(cornerRadius: 16).stroke(AppColors.border, lineWidth: primary ? 0 : 1.5) }
            .contentShape(RoundedRectangle(cornerRadius: 16))
    }
}

#Preview("受信申請あり") {
    NavigationStack {
        IncomingFriendRequestsView(
            store: FriendStore(
                repository: InMemoryFriendRepository(),
                incomingRequests: [FriendPreviewData.incomingRequest]
            )
        )
    }
}
