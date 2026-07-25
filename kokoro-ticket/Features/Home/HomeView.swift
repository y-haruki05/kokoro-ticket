import SwiftUI

struct HomeView: View {
    private let tickets = MockTickets.received

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                HomeHeaderView()

                VStack(alignment: .leading, spacing: 7) {
                    Text("おはよう！")
                        .font(.system(size: 25, weight: .bold, design: .rounded))

                    Text("今日はどんなきもちを届ける？")
                        .font(.system(size: 17, weight: .medium, design: .rounded))
                        .foregroundStyle(AppColors.textSecondary)
                }
                .foregroundStyle(AppColors.textPrimary)

                VStack(alignment: .leading, spacing: 14) {
                    Text("今日のこころチケット")
                        .font(.system(size: 19, weight: .bold, design: .rounded))
                        .foregroundStyle(AppColors.textPrimary)

                    MainTicketCardView(ticket: MockTickets.today)
                }

                receivedTicketsSection
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 118)
        }
        .background(AppColors.background.ignoresSafeArea())
        .navigationBarHidden(true)
    }

    private var receivedTicketsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("受け取ったチケット")
                    .font(.system(size: 19, weight: .bold, design: .rounded))
                    .foregroundStyle(AppColors.textPrimary)

                Spacer()

                Button("すべて見る") {}
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppColors.primaryDark)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 14) {
                    ForEach(tickets) { ticket in
                        TicketCardView(ticket: ticket)
                    }
                }
                .padding(.vertical, 8)
            }
            .contentMargins(.horizontal, 1, for: .scrollContent)
        }
    }
}

#Preview {
    NavigationStack {
        HomeView()
    }
}
