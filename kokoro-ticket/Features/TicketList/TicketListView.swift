import SwiftUI

struct TicketListView: View {
    let store: TicketStore
    let onCreateTicket: () -> Void
    var onDetailVisibilityChange: (Bool) -> Void = { _ in }

    @State private var selectedStatus: TicketStatus = .draft

    var body: some View {
        VStack(spacing: 0) {
            Text("チケット一覧")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(AppColors.primary)
                .frame(maxWidth: .infinity)
                .padding(.top, 16)
                .padding(.bottom, 22)

            TicketListSegmentedControl(selection: $selectedStatus)

            ScrollView {
                if filteredTickets.isEmpty {
                    TicketListEmptyView(onCreateTicket: onCreateTicket)
                } else {
                    LazyVStack(spacing: 14) {
                        ForEach(filteredTickets) { ticket in
                            NavigationLink(value: ticket.id) {
                                TicketListCardView(ticket: ticket)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 22)
                    .padding(.bottom, 112)
                }
            }
            .contentMargins(.top, 1, for: .scrollContent)
        }
        .background(AppColors.background.ignoresSafeArea())
        .navigationBarHidden(true)
        .navigationDestination(for: TicketListItem.ID.self) { ticketID in
            TicketDetailView(ticketID: ticketID, store: store)
                .onAppear {
                    onDetailVisibilityChange(true)
                }
                .onDisappear {
                    onDetailVisibilityChange(false)
                }
        }
    }

    private var filteredTickets: [TicketListItem] {
        store.tickets(for: selectedStatus)
    }
}

#Preview {
    NavigationStack {
        TicketListView(
            store: TicketStore(tickets: MockTicketListItems.items),
            onCreateTicket: {}
        )
    }
}
