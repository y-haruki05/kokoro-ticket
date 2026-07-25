import SwiftUI

struct TicketFriendSelectionView: View {
    let ticket: TicketListItem
    let friends: [Friend]
    let onSend: (Friend) -> Bool

    @Environment(\.dismiss) private var dismiss
    @State private var selectedFriend: Friend?
    @State private var isShowingConfirmation = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        Text("送り先を選ぼう")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundStyle(AppColors.textPrimary)

                        Text(ticket.title)
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundStyle(AppColors.primaryDark)

                        ForEach(friends) { friend in
                            Button {
                                selectedFriend = friend
                            } label: {
                                HStack {
                                    Image(systemName: "person.fill")
                                        .foregroundStyle(AppColors.primary)
                                        .frame(width: 42, height: 42)
                                        .background(AppColors.primarySoft)
                                        .clipShape(Circle())

                                    Text(friend.displayName)
                                        .font(.system(size: 17, weight: .bold, design: .rounded))
                                        .foregroundStyle(AppColors.textPrimary)

                                    Spacer()
                                }
                                .padding(16)
                                .background(
                                    selectedFriend == friend
                                        ? AppColors.primarySoft
                                        : AppColors.cardBackground
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(
                                            selectedFriend == friend
                                                ? AppColors.primary
                                                : AppColors.border,
                                            lineWidth: selectedFriend == friend ? 2 : 1
                                        )
                                }
                                .contentShape(RoundedRectangle(cornerRadius: 20))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(20)
                }

                Button {
                    isShowingConfirmation = true
                } label: {
                    Text("送信内容を確認")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            selectedFriend == nil
                                ? AppColors.textSecondary.opacity(0.35)
                                : AppColors.primary
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        .contentShape(RoundedRectangle(cornerRadius: 18))
                }
                .buttonStyle(.plain)
                .disabled(selectedFriend == nil)
                .padding(20)
                .background(.ultraThinMaterial)
            }
            .background(AppColors.background.ignoresSafeArea())
            .navigationTitle("チケット送信")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
            .confirmationDialog(
                confirmationTitle,
                isPresented: $isShowingConfirmation,
                titleVisibility: .visible
            ) {
                Button("送信する") {
                    guard let selectedFriend else { return }
                    if onSend(selectedFriend) {
                        dismiss()
                    }
                }
                Button("キャンセル", role: .cancel) {}
            }
        }
    }

    private var confirmationTitle: String {
        guard let selectedFriend else {
            return "送り先を選択してください"
        }
        return "\(selectedFriend.displayName)へ「\(ticket.title)」を送りますか？"
    }
}

#Preview {
    TicketFriendSelectionView(
        ticket: MockTicketListItems.items[0],
        friends: MockFriends.items,
        onSend: { _ in true }
    )
}
