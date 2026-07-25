import SwiftUI

struct TicketDetailView: View {
    let ticket: TicketListItem
    var onUseTicket: (TicketListItem) -> Void = { _ in }

    @Environment(\.dismiss) private var dismiss
    @State private var isShowingUseConfirmation = false

    var body: some View {
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
        .background(AppColors.background.ignoresSafeArea())
        .navigationBarHidden(true)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            bottomAction
        }
        .confirmationDialog(
            "このチケットを使用しますか？",
            isPresented: $isShowingUseConfirmation,
            titleVisibility: .visible
        ) {
            Button("使用する") {
                onUseTicket(ticket)
            }
            Button("キャンセル", role: .cancel) {}
        }
    }

    @ViewBuilder
    private var bottomAction: some View {
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
}

#Preview {
    NavigationStack {
        TicketDetailView(ticket: MockTicketListItems.items[0])
    }
}
