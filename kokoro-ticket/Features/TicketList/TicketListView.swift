import SwiftUI

struct TicketListView: View {
    let tickets: [TicketListItem]
    let onCreateTicket: () -> Void

    @State private var selectedCategory: TicketListCategory = .received

    var body: some View {
        VStack(spacing: 0) {
            Text("チケット一覧")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(AppColors.primary)
                .frame(maxWidth: .infinity)
                .padding(.top, 16)
                .padding(.bottom, 22)

            TicketListSegmentedControl(selection: $selectedCategory)
                .padding(.horizontal, 20)

            ScrollView {
                if filteredTickets.isEmpty {
                    TicketListEmptyView(onCreateTicket: onCreateTicket)
                } else {
                    LazyVStack(spacing: 14) {
                        ForEach(filteredTickets) { ticket in
                            TicketListCardView(ticket: ticket)
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
    }

    private var filteredTickets: [TicketListItem] {
        tickets
            .filter { $0.category == selectedCategory }
            .sorted { $0.createdAt > $1.createdAt }
    }
}

#Preview {
    NavigationStack {
        TicketListView(
            tickets: MockTicketListItems.items,
            onCreateTicket: {}
        )
    }
}
