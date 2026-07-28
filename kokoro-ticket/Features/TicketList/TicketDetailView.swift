import SwiftUI

struct TicketDetailView: View {
    let ticketID: TicketListItem.ID
    let store: TicketStore
    var friendStore: FriendStore? = nil
    var onTicketSent: () -> Void = {}
    var onTicketCompleted: () -> Void = {}

    @Environment(\.dismiss) private var dismiss
    @State private var pendingAction: TicketDetailAction?
    @State private var isShowingFriendSelection = false
    @State private var isShowingEditor = false
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
                    if let friendStore {
                        TicketFriendSelectionView(
                            ticket: ticket,
                            friendStore: friendStore,
                            ticketStore: store,
                            onSent: {
                                isShowingFriendSelection = false
                                onTicketSent()
                                dismiss()
                            }
                        )
                    }
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
        .alert(
            "チケットを完了できませんでした",
            isPresented: Binding(
                get: { store.completionError != nil },
                set: { if !$0 { store.clearCompletionError() } }
            ),
            presenting: store.completionError
        ) { _ in
            Button("OK") { store.clearCompletionError() }
        } message: { error in
            Text(error.localizedDescription)
        }
    }

    @ViewBuilder
    private func actionArea(for ticket: TicketListItem) -> some View {
        if ticket.detailActions.isEmpty {
            VStack(spacing: 4) {
                Text(readOnlyStatusText(for: ticket))
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppColors.textSecondary)

                if let completedAt = ticket.completedAt {
                    Text(completedAt.formatted(date: .numeric, time: .shortened))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(AppColors.textSecondary.opacity(0.8))
                }
            }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(AppColors.cardBackground)
                .overlay(alignment: .top) {
                    Divider().overlay(AppColors.border.opacity(0.7))
                }
        } else {
            HStack(spacing: 12) {
                ForEach(ticket.detailActions) { action in
                    actionButton(action)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 8)
            .background(AppColors.cardBackground)
            .overlay(alignment: .top) {
                Divider().overlay(AppColors.border.opacity(0.7))
            }
        }
    }

    private func actionButton(_ action: TicketDetailAction) -> some View {
        Button {
            handle(action)
        } label: {
            ZStack {
                Text(action.title)
                    .opacity(isActionLoading(action) ? 0 : 1)
                if isActionLoading(action) {
                    ProgressView()
                        .tint(.white)
                }
            }
                .font(.system(size: 16, weight: .bold, design: .rounded))
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
        .disabled(store.isCompleting || store.isRequesting)
    }

    private func handle(_ action: TicketDetailAction) {
        switch action {
        case .edit:
            isShowingEditor = true
        case .send:
            isShowingFriendSelection = true
        case .delete, .acknowledgeReceipt, .requestUsage, .complete:
            pendingAction = action
        }
    }

    private func performPendingAction() {
        guard let action = pendingAction else { return }

        if action == .complete {
            completeTicket()
            return
        }
        if action == .acknowledgeReceipt || action == .requestUsage {
            pendingAction = nil
            Task {
                if action == .acknowledgeReceipt {
                    _ = await store.acknowledgeTicket(id: ticketID)
                } else {
                    _ = await store.requestUsage(id: ticketID)
                }
            }
            return
        }

        let succeeded: Bool

        switch action {
        case .delete:
            succeeded = store.deleteDraft(id: ticketID)
        case .acknowledgeReceipt, .requestUsage:
            succeeded = false
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
            !store.isCompleting,
            !isShowingCompletionAnimation,
            let ticket = store.ticket(id: ticketID),
            ticket.status == .requested,
            ticket.perspective != .receiver
        else {
            pendingAction = nil
            return
        }

        pendingAction = nil
        Task {
            guard await store.completeTicket(id: ticketID) else {
                return
            }
            isShowingCompletionAnimation = true
        }
    }

    private func finishCompletionAnimation() {
        isShowingCompletionAnimation = false
        onTicketCompleted()
    }

    private var confirmationBinding: Binding<Bool> {
        Binding(
            get: { pendingAction != nil },
            set: { if !$0 { pendingAction = nil } }
        )
    }

    private var confirmationTitle: String {
        switch pendingAction {
        case .delete: "このチケットを削除しますか？"
        case .acknowledgeReceipt: "このチケットを受け取りますか？"
        case .requestUsage: "このチケットを使いますか？"
        case .complete: "チケットを完了しますか？"
        case .edit, .send, .none: ""
        }
    }

    private var confirmationButtonTitle: String {
        switch pendingAction {
        case .delete: "削除する"
        case .acknowledgeReceipt: "受け取る"
        case .requestUsage: "使用リクエストを送る"
        case .complete: "完了する"
        case .edit, .send, .none: "実行する"
        }
    }

    private func actionForeground(_ action: TicketDetailAction) -> Color {
        switch action {
        case .delete: .red
        case .edit: AppColors.primaryDark
        case .send, .acknowledgeReceipt, .requestUsage, .complete: .white
        }
    }

    private func actionBackground(_ action: TicketDetailAction) -> Color {
        switch action {
        case .edit, .delete: AppColors.cardBackground
        case .send, .acknowledgeReceipt, .requestUsage, .complete: AppColors.primary
        }
    }

    private func actionBorder(_ action: TicketDetailAction) -> Color {
        action == .delete ? .red.opacity(0.65) : AppColors.primary
    }

    private func isActionLoading(_ action: TicketDetailAction) -> Bool {
        if action == .complete {
            return store.isCompleting
        }
        return store.isRequesting
            && (action == .acknowledgeReceipt || action == .requestUsage)
    }

    private func readOnlyStatusText(for ticket: TicketListItem) -> String {
        switch (ticket.perspective, ticket.status) {
        case (_, .completed):
            "完了しました"
        case (.receiver, .requested):
            "相手の対応待ち"
        case (.sender, .requested):
            "対応待ち"
        case (.sender, .sent), (.sender, .received):
            "送信済みです"
        default:
            ticket.statusDisplayName
        }
    }

    private var unavailableContent: some View {
        VStack(spacing: 18) {
            TicketDetailHeaderView {
                dismiss()
            }

            Spacer()

            VStack(spacing: 12) {
                Image("cat_sad")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 100)
                    .accessibilityHidden(true)

                Text("チケットが見つかりません")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppColors.textSecondary)
            }

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
            store: TicketStore(tickets: MockTicketListItems.items),
            friendStore: FriendStore(
                repository: InMemoryFriendRepository(
                    friends: [FriendPreviewData.friend]
                ),
                friends: [FriendPreviewData.friend]
            )
        )
    }
}

#Preview("requested・送り主") {
    let ticket = MockTicketListItems.items[3].viewed(as: .sender)
    NavigationStack {
        TicketDetailView(
            ticketID: ticket.id,
            store: TicketStore(previewTickets: [ticket])
        )
    }
}

#Preview("requested・受取人") {
    let ticket = MockTicketListItems.items[3].viewed(as: .receiver)
    NavigationStack {
        TicketDetailView(
            ticketID: ticket.id,
            store: TicketStore(previewTickets: [ticket])
        )
    }
}

#Preview("完了処理中") {
    let ticket = MockTicketListItems.items[3].viewed(as: .sender)
    NavigationStack {
        TicketDetailView(
            ticketID: ticket.id,
            store: TicketStore(
                previewTickets: [ticket],
                isCompleting: true
            )
        )
    }
}

#Preview("完了エラー") {
    let ticket = MockTicketListItems.items[3].viewed(as: .sender)
    NavigationStack {
        TicketDetailView(
            ticketID: ticket.id,
            store: TicketStore(
                previewTickets: [ticket],
                completionError: .ticketCompletionFailed
            )
        )
    }
}

#Preview("completed詳細") {
    let ticket = MockTicketListItems.items[4].viewed(as: .receiver)
    NavigationStack {
        TicketDetailView(
            ticketID: ticket.id,
            store: TicketStore(previewTickets: [ticket])
        )
    }
}
