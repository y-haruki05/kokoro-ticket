import SwiftUI

struct TicketDetailView: View {
    let ticketID: TicketListItem.ID
    let store: TicketStore

    @Environment(\.dismiss) private var dismiss
    @State private var pendingAction: TicketDetailAction?
    @State private var isShowingFriendSelection = false
    @State private var isShowingEditor = false
    @State private var isCompletingTicket = false
    @State private var isShowingCompletionAnimation = false

    var body: some View {
        Group {
            if let ticket = store.ticket(id: ticketID) {
                ScrollView {
                    VStack(spacing: 28) {
                        TicketDetailHeaderView {
                            dismiss()
                        }

                        TicketDetailCardView(ticket: ticket)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 24)
                }
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    actionArea(for: ticket)
                }
                .sheet(isPresented: $isShowingFriendSelection) {
                    TicketFriendSelectionView(
                        ticket: ticket,
                        friends: MockFriends.items,
                        onSend: { friend in
                            store.send(id: ticketID, to: friend)
                        }
                    )
                }
                .sheet(isPresented: $isShowingEditor) {
                    TicketDraftEditView(
                        ticket: ticket,
                        onSave: { title, message in
                            store.updateDraft(
                                id: ticketID,
                                title: title,
                                message: message
                            )
                        }
                    )
                }
            } else {
                unavailableContent
            }
        }
        .background(AppColors.background.ignoresSafeArea())
        .navigationBarHidden(true)
        .confirmationDialog(
            confirmationTitle,
            isPresented: confirmationBinding,
            titleVisibility: .visible
        ) {
            Button(confirmationButtonTitle, role: pendingAction == .delete ? .destructive : nil) {
                performPendingAction()
            }
            Button("キャンセル", role: .cancel) {
                pendingAction = nil
            }
        } message: {
            if pendingAction == .complete {
                Text("チケットの内容を実行したことを確認してください。")
            }
        }
        .fullScreenCover(isPresented: $isShowingCompletionAnimation) {
            if let ticket = store.ticket(id: ticketID) {
                TicketUsageAnimationView(ticket: ticket) {
                    finishCompletionAnimation()
                }
            }
        }
    }

    @ViewBuilder
    private func actionArea(for ticket: TicketListItem) -> some View {
        if ticket.detailActions.isEmpty {
            Text("完了したチケットです")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(AppColors.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(.ultraThinMaterial)
        } else {
            HStack(spacing: 12) {
                ForEach(ticket.detailActions) { action in
                    actionButton(action)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 8)
            .background(.ultraThinMaterial)
        }
    }

    private func actionButton(_ action: TicketDetailAction) -> some View {
        Button {
            handle(action)
        } label: {
            Text(action.title)
                .font(.system(size: action == .simulateReceive ? 13 : 16, weight: .bold, design: .rounded))
                .foregroundStyle(actionForeground(action))
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(actionBackground(action))
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .overlay {
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(actionBorder(action), lineWidth: 1.5)
                }
                .contentShape(RoundedRectangle(cornerRadius: 18))
        }
        .buttonStyle(.plain)
        .disabled(isCompletingTicket)
    }

    private func handle(_ action: TicketDetailAction) {
        switch action {
        case .edit:
            isShowingEditor = true
        case .send:
            isShowingFriendSelection = true
        case .delete, .simulateReceive, .requestUsage, .complete:
            pendingAction = action
        }
    }

    private func performPendingAction() {
        guard let action = pendingAction else { return }

        if action == .complete {
            completeTicket()
            return
        }

        let succeeded: Bool

        switch action {
        case .delete:
            succeeded = store.deleteDraft(id: ticketID)
        case .simulateReceive:
            succeeded = store.receive(id: ticketID)
        case .requestUsage:
            succeeded = store.requestUsage(id: ticketID)
        case .edit, .send, .complete:
            succeeded = false
        }

        pendingAction = nil
        if action == .delete && succeeded {
            dismiss()
        }
    }

    private func completeTicket() {
        guard
            !isCompletingTicket,
            !isShowingCompletionAnimation,
            store.ticket(id: ticketID)?.status == .requested
        else {
            pendingAction = nil
            return
        }

        pendingAction = nil
        isCompletingTicket = true

        guard store.complete(id: ticketID) else {
            isCompletingTicket = false
            return
        }

        isShowingCompletionAnimation = true
    }

    private func finishCompletionAnimation() {
        guard isCompletingTicket else { return }
        isShowingCompletionAnimation = false
        isCompletingTicket = false
    }

    private var confirmationBinding: Binding<Bool> {
        Binding(
            get: { pendingAction != nil },
            set: { if !$0 { pendingAction = nil } }
        )
    }

    private var confirmationTitle: String {
        switch pendingAction {
        case .delete: "この作り置きチケットを削除しますか？"
        case .simulateReceive: "相手が受け取った状態へ進めますか？"
        case .requestUsage: "このチケットの使用をリクエストしますか？"
        case .complete: "チケットを完了しますか？"
        case .edit, .send, .none: ""
        }
    }

    private var confirmationButtonTitle: String {
        switch pendingAction {
        case .delete: "削除する"
        case .simulateReceive: "受け取り済みにする"
        case .requestUsage: "リクエストする"
        case .complete: "完了する"
        case .edit, .send, .none: "実行する"
        }
    }

    private func actionForeground(_ action: TicketDetailAction) -> Color {
        switch action {
        case .delete: .red
        case .edit, .simulateReceive: AppColors.primaryDark
        case .send, .requestUsage, .complete: .white
        }
    }

    private func actionBackground(_ action: TicketDetailAction) -> Color {
        switch action {
        case .edit, .delete, .simulateReceive: AppColors.cardBackground
        case .send, .requestUsage, .complete: AppColors.primary
        }
    }

    private func actionBorder(_ action: TicketDetailAction) -> Color {
        action == .delete ? .red.opacity(0.65) : AppColors.primary
    }

    private var unavailableContent: some View {
        VStack(spacing: 18) {
            TicketDetailHeaderView {
                dismiss()
            }

            Spacer()

            Text("チケットが見つかりません")
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundStyle(AppColors.textSecondary)

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }
}

#Preview {
    NavigationStack {
        TicketDetailView(
            ticketID: MockTicketListItems.items[0].id,
            store: TicketStore(tickets: MockTicketListItems.items)
        )
    }
}
