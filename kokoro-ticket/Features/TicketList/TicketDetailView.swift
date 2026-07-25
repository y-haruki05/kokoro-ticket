import SwiftUI

struct TicketDetailView: View {
    let ticketID: TicketListItem.ID
    let store: TicketStore

    @Environment(\.dismiss) private var dismiss
    @State private var isShowingUseConfirmation = false
    @State private var isShowingUsageAnimation = false

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
                    bottomAction(for: ticket)
                }
            } else {
                unavailableContent
            }
        }
        .background(AppColors.background.ignoresSafeArea())
        .navigationBarHidden(true)
        .confirmationDialog(
            "このチケットを使用しますか？",
            isPresented: $isShowingUseConfirmation,
            titleVisibility: .visible
        ) {
            Button("使用する") {
                startUsageAnimation()
            }
            Button("キャンセル", role: .cancel) {}
        }
        .fullScreenCover(isPresented: $isShowingUsageAnimation) {
            if let ticket = store.ticket(id: ticketID) {
                TicketUsageAnimationView(ticket: ticket) {
                    finishUsage()
                }
            }
        }
    }

    @ViewBuilder
    private func bottomAction(for ticket: TicketListItem) -> some View {
        if ticket.status == .unused {
            Button {
                isShowingUseConfirmation = true
            } label: {
                Text("このチケットを使う")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(AppColors.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .contentShape(RoundedRectangle(cornerRadius: 18))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 8)
            .background(.ultraThinMaterial)
        } else {
            Text("使用済みです")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(AppColors.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(.ultraThinMaterial)
        }
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

    private func startUsageAnimation() {
        guard
            !isShowingUsageAnimation,
            store.ticket(id: ticketID)?.isUsed == false
        else {
            return
        }

        isShowingUsageAnimation = true
    }

    private func finishUsage() {
        _ = store.markAsUsed(id: ticketID)
        isShowingUsageAnimation = false
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
