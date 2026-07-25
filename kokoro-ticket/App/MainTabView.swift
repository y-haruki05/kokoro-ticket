import SwiftUI

struct MainTabView: View {
    @State private var selection: AppTab = .home
    @State private var ticketStore = TicketStore(
        tickets: MockTicketListItems.items
    )
    @State private var isShowingTicketDetail = false

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selection) {
                NavigationStack {
                    HomeView()
                }
                .tag(AppTab.home)

                NavigationStack {
                    TicketListView(
                        store: ticketStore,
                        onCreateTicket: {
                            selection = .create
                        },
                        onDetailVisibilityChange: { isShowing in
                            isShowingTicketDetail = isShowing
                        }
                    )
                }
                    .tag(AppTab.tickets)

                TicketCreationFlowView(
                    onSave: { ticket in
                        ticketStore.add(savedTicket: ticket)
                    },
                    onClose: {
                        selection = .home
                    }
                )
                    .tag(AppTab.create)

                NavigationStack {
                    MemoriesView(
                        store: ticketStore,
                        onCreateTicket: {
                            selection = .create
                        },
                        onDetailVisibilityChange: { isShowing in
                            isShowingTicketDetail = isShowing
                        }
                    )
                }
                    .tag(AppTab.memories)

                placeholderScreen(title: "マイページ")
                    .tag(AppTab.profile)
            }
            .toolbar(.hidden, for: .tabBar)

            if selection != .create && !isShowingTicketDetail {
                AppTabBar(selection: $selection)
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }

    private func placeholderScreen(title: String) -> some View {
        NavigationStack {
            Text(title)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(AppColors.textPrimary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(AppColors.background)
                .navigationTitle(title)
        }
    }
}

private enum AppTab: String, CaseIterable {
    case home = "ホーム"
    case tickets = "チケット"
    case create = "作る"
    case memories = "思い出"
    case profile = "マイページ"

    var iconName: String {
        switch self {
        case .home: "house.fill"
        case .tickets: "ticket"
        case .create: "plus"
        case .memories: "photo"
        case .profile: "person"
        }
    }
}

private struct AppTabBar: View {
    @Binding var selection: AppTab

    var body: some View {
        HStack(alignment: .bottom, spacing: 0) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                Button {
                    selection = tab
                } label: {
                    if tab == .create {
                        createTab(tab)
                    } else {
                        standardTab(tab)
                    }
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
                .accessibilityLabel(tab.rawValue)
                .accessibilityAddTraits(selection == tab ? .isSelected : [])
            }
        }
        .padding(.horizontal, 8)
        .padding(.top, 10)
        .padding(.bottom, 6)
        .background(.ultraThinMaterial)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(AppColors.border.opacity(0.55))
                .frame(height: 1)
        }
    }

    private func standardTab(_ tab: AppTab) -> some View {
        VStack(spacing: 5) {
            Image(systemName: tab.iconName)
                .font(.system(size: 21, weight: .semibold))

            Text(tab.rawValue)
                .font(.system(size: 10, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .foregroundStyle(selection == tab ? AppColors.primary : AppColors.textSecondary)
        .frame(height: 50)
    }

    private func createTab(_ tab: AppTab) -> some View {
        VStack(spacing: 4) {
            Image(systemName: tab.iconName)
                .font(.system(size: 27, weight: .medium))
                .foregroundStyle(.white)
                .frame(width: 58, height: 58)
                .background(AppColors.primary)
                .clipShape(Circle())
                .shadow(color: AppColors.primary.opacity(0.25), radius: 8, y: 4)

            Text(tab.rawValue)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(
                    selection == tab ? AppColors.primary : AppColors.textSecondary
                )
        }
        .offset(y: -13)
    }
}

#Preview {
    MainTabView()
}
