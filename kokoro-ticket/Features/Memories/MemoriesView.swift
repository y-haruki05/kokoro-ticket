import SwiftUI

struct MemoriesView: View {
    let store: TicketStore
    let onCreateTicket: () -> Void
    var onDetailVisibilityChange: (Bool) -> Void = { _ in }

    @State private var hasAppeared = false

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 8) {
                Text("思い出")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(AppColors.primary)

                Text("使ったチケットを思い出として残そう")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(AppColors.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 16)
            .padding(.bottom, 22)

            ScrollView {
                if usedTickets.isEmpty {
                    MemoriesEmptyView(onCreateTicket: onCreateTicket)
                } else {
                    LazyVStack(spacing: 14) {
                        ForEach(usedTickets) { ticket in
                            NavigationLink(value: ticket.id) {
                                MemoryTicketCardView(ticket: ticket)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 112)
                    .opacity(hasAppeared ? 1 : 0)
                }
            }
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
        .onAppear {
            withAnimation(.easeOut(duration: 0.25)) {
                hasAppeared = true
            }
        }
    }

    private var usedTickets: [TicketListItem] {
        store.tickets
            .filter { $0.status == .completed }
            .sorted {
                ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast)
            }
    }
}

#Preview {
    NavigationStack {
        MemoriesView(
            store: TicketStore(tickets: MockTicketListItems.items),
            onCreateTicket: {}
        )
    }
}
