import SwiftUI

struct TicketFriendSelectionView: View {
    let ticket: TicketListItem
    let friendStore: FriendStore
    let ticketStore: TicketStore
    let onSent: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedFriend: Friend?
    @State private var showsConfirmation = false

    var body: some View {
        NavigationStack {
            Group {
                if showsConfirmation, let selectedFriend {
                    confirmationView(friend: selectedFriend)
                } else {
                    selectionView
                }
            }
            .background(AppColors.background.ignoresSafeArea())
            .navigationTitle(showsConfirmation ? "送信内容の確認" : "チケット送信")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(showsConfirmation ? "戻る" : "閉じる") {
                        if showsConfirmation {
                            showsConfirmation = false
                        } else {
                            dismiss()
                        }
                    }
                    .disabled(ticketStore.isSending)
                }
            }
        }
        .interactiveDismissDisabled(ticketStore.isSending)
        .friendErrorAlert(store: friendStore)
        .alert(
            "チケットを送信できませんでした",
            isPresented: Binding(
                get: { ticketStore.sendError != nil },
                set: { if !$0 { ticketStore.clearSendError() } }
            ),
            presenting: ticketStore.sendError
        ) { _ in
            Button("OK") { ticketStore.clearSendError() }
        } message: { error in
            Text(error.localizedDescription)
        }
        .task {
            if friendStore.friends.isEmpty {
                await friendStore.reload()
            }
        }
    }

    private var selectionView: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("送り先を選ぼう")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(AppColors.textPrimary)

                    Text(ticket.title)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(AppColors.primaryDark)

                    if friendStore.isLoading {
                        ProgressView()
                            .tint(AppColors.primary)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 40)
                    } else if friendStore.friends.isEmpty {
                        ContentUnavailableView(
                            "送信できるフレンドがいません",
                            systemImage: "person.2",
                            description: Text("先にマイページからフレンドを追加してください")
                        )
                        .padding(.top, 28)
                    } else {
                        ForEach(friendStore.friends) { friend in
                            friendButton(friend)
                        }
                    }
                }
                .padding(20)
            }

            PrimaryActionButton(
                title: "送信内容を確認",
                isDisabled: selectedFriend == nil
            ) {
                showsConfirmation = true
            }
            .padding(20)
            .background(.ultraThinMaterial)
        }
    }

    private func friendButton(_ friend: Friend) -> some View {
        Button {
            selectedFriend = friend
        } label: {
            HStack(spacing: 14) {
                ProfileAvatarPlaceholderView()
                    .scaleEffect(0.6)
                    .frame(width: 52, height: 52)

                VStack(alignment: .leading, spacing: 4) {
                    Text(friend.displayName)
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(AppColors.textPrimary)
                    Text(friend.friendCode)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .tracking(1)
                        .foregroundStyle(AppColors.textSecondary)
                }
                Spacer()
            }
            .padding(16)
            .background(selectedFriend == friend ? AppColors.primarySoft : AppColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay {
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        selectedFriend == friend ? AppColors.primary : AppColors.border,
                        lineWidth: selectedFriend == friend ? 2 : 1
                    )
            }
            .contentShape(RoundedRectangle(cornerRadius: 20))
        }
        .buttonStyle(.plain)
    }

    private func confirmationView(friend: Friend) -> some View {
        VStack(spacing: 22) {
            ScrollView {
                VStack(spacing: 22) {
                    Text("この内容で送りますか？")
                        .font(.system(size: 23, weight: .bold, design: .rounded))
                        .foregroundStyle(AppColors.textPrimary)

                    TicketDetailCardView(ticket: ticket)

                    VStack(spacing: 8) {
                        Text("送り先")
                            .font(.system(size: 13, design: .rounded))
                            .foregroundStyle(AppColors.textSecondary)
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
                .padding(20)
            }

            HStack(spacing: 14) {
                Button {
                    showsConfirmation = false
                } label: {
                    Text("キャンセル")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(AppColors.primaryDark)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(AppColors.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        .overlay {
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(AppColors.border, lineWidth: 1.5)
                        }
                }
                .buttonStyle(.plain)
                .disabled(ticketStore.isSending)

                PrimaryActionButton(
                    title: "送信",
                    isLoading: ticketStore.isSending
                ) {
                    Task {
                        if await ticketStore.sendTicket(id: ticket.id, to: friend) {
                            onSent()
                        }
                    }
                }
            }
            .padding(20)
            .background(.ultraThinMaterial)
        }
    }
}

#Preview("フレンド選択") {
    TicketFriendSelectionView(
        ticket: MockTicketListItems.items[0],
        friendStore: FriendStore(
            repository: InMemoryFriendRepository(
                friends: [FriendPreviewData.friend]
            ),
            friends: [FriendPreviewData.friend]
        ),
        ticketStore: TicketStore(tickets: [MockTicketListItems.items[0]]),
        onSent: {}
    )
}

#Preview("送信中") {
    TicketFriendSelectionView(
        ticket: MockTicketListItems.items[0],
        friendStore: FriendStore(
            repository: InMemoryFriendRepository(
                friends: [FriendPreviewData.friend]
            ),
            friends: [FriendPreviewData.friend]
        ),
        ticketStore: TicketStore(
            repository: InMemoryTicketRepository(
                tickets: [Ticket(item: MockTicketListItems.items[0])]
            ),
            isSending: true
        ),
        onSent: {}
    )
}
