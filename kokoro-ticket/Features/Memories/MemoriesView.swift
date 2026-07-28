import SwiftUI

struct MemoriesView: View {
    let store: TicketStore
    let onCreateTicket: () -> Void
    var onDetailVisibilityChange: (Bool) -> Void = { _ in }

    @State private var sortOrder: MemorySortOrder = .newest
    @State private var hasAppeared = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                content
                    .padding(.horizontal, 20)
                    .padding(.bottom, 112)
            }
            .refreshable {
                await store.reloadCompletedTickets()
            }
        }
        .background(AppColors.background.ignoresSafeArea())
        .navigationBarHidden(true)
        .navigationDestination(for: TicketListItem.ID.self) { ticketID in
            MemoryDetailView(ticketID: ticketID, store: store)
                .onAppear { onDetailVisibilityChange(true) }
                .onDisappear { onDetailVisibilityChange(false) }
        }
        .onAppear {
            guard !hasAppeared else { return }
            withAnimation(.easeOut(duration: 0.25)) {
                hasAppeared = true
            }
        }
        .task {
            await store.reloadCompletedTickets()
        }
    }

    private var header: some View {
        VStack(spacing: 5) {
            Text("思い出")
                .font(.system(size: 25, weight: .bold, design: .rounded))
                .foregroundStyle(AppColors.primary)

            Text("\(completedTickets.count)件の思い出があります")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 15)
        .padding(.bottom, 15)
        .background(AppColors.cardBackground)
        .overlay(alignment: .bottom) {
            Divider().overlay(AppColors.border.opacity(0.55))
        }
    }

    @ViewBuilder
    private var content: some View {
        if store.isReloadingCompleted && completedTickets.isEmpty {
            memoriesLoading
        } else if let error = store.completionError, completedTickets.isEmpty {
            memoriesError(error)
        } else if completedTickets.isEmpty {
            MemoriesEmptyView(onCreateTicket: onCreateTicket)
        } else {
            LazyVStack(alignment: .leading, spacing: 20) {
                albumIntro
                sortPicker

                ForEach(groupedMemories) { group in
                    memorySection(group)
                }
            }
            .padding(.top, 18)
            .opacity(hasAppeared ? 1 : 0)
            .scaleEffect(
                hasAppeared || reduceMotion ? 1 : 0.99,
                anchor: .top
            )
        }
    }

    private var albumIntro: some View {
        HStack(spacing: 14) {
            Image("cat_happy")
                .resizable()
                .scaledToFit()
                .frame(width: 76, height: 76)

            VStack(alignment: .leading, spacing: 4) {
                Text("これまでの思い出")
                    .font(.system(size: 19, weight: .bold, design: .rounded))
                    .foregroundStyle(AppColors.textPrimary)
                Text("大切な時間を、ゆっくり振り返ろう")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(AppColors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(AppColors.primarySoft.opacity(0.55))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var sortPicker: some View {
        HStack {
            Text("並び替え")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(AppColors.textPrimary)

            Spacer()

            HStack(spacing: 4) {
                ForEach(MemorySortOrder.allCases) { order in
                    Button {
                        withAnimation(.easeInOut(duration: 0.18)) {
                            sortOrder = order
                        }
                    } label: {
                        Text(order.title)
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                sortOrder == order ? Color.white : AppColors.textSecondary
                            )
                            .frame(maxWidth: .infinity)
                            .frame(height: 38)
                            .background(
                                sortOrder == order
                                    ? AppColors.primary
                                    : AppColors.primarySoft.opacity(0.55)
                            )
                            .clipShape(Capsule())
                            .contentShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(sortOrder == order ? .isSelected : [])
                }
            }
            .frame(maxWidth: 190)
        }
    }

    private func memorySection(_ group: MemoryMonthGroup) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(group.title)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(AppColors.primaryDark)
                .padding(.leading, 4)

            ForEach(group.tickets) { ticket in
                NavigationLink(value: ticket.id) {
                    MemoryTicketCardView(ticket: ticket)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var memoriesLoading: some View {
        VStack(spacing: 14) {
            ProgressView()
                .tint(AppColors.primary)
            Text("思い出をひらいています")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 90)
    }

    private func memoriesError(_ error: AppError) -> some View {
        VStack(spacing: 14) {
            Image("cat_sad")
                .resizable()
                .scaledToFit()
                .frame(width: 112, height: 112)
            Text("思い出を読み込めませんでした")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(AppColors.textPrimary)
            Text(error.localizedDescription)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(3)
            Button("もう一度読み込む") {
                Task { await store.reloadCompletedTickets() }
            }
            .font(.system(size: 14, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
            .padding(.horizontal, 24)
            .frame(height: 46)
            .background(AppColors.primary)
            .clipShape(Capsule())
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 44)
    }

    private var completedTickets: [TicketListItem] {
        store.completedTickets.filter { $0.status == .completed && $0.completedAt != nil }
    }

    private var groupedMemories: [MemoryMonthGroup] {
        let calendar = Calendar.current
        let sorted = completedTickets.sorted {
            let lhs = $0.completedAt ?? .distantPast
            let rhs = $1.completedAt ?? .distantPast
            return sortOrder == .newest ? lhs > rhs : lhs < rhs
        }
        let grouped = Dictionary(grouping: sorted) { ticket in
            calendar.dateInterval(of: .month, for: ticket.completedAt ?? ticket.updatedAt)?.start
                ?? ticket.completedAt
                ?? ticket.updatedAt
        }

        return grouped
            .map { month, tickets in
                MemoryMonthGroup(month: month, tickets: tickets)
            }
            .sorted {
                sortOrder == .newest ? $0.month > $1.month : $0.month < $1.month
            }
    }
}

private enum MemorySortOrder: String, CaseIterable, Identifiable {
    case newest
    case oldest

    var id: Self { self }
    var title: String { self == .newest ? "新しい順" : "古い順" }
}

private struct MemoryMonthGroup: Identifiable {
    let month: Date
    let tickets: [TicketListItem]

    var id: Date { month }
    var title: String {
        month.formatted(
            Date.FormatStyle()
                .year(.defaultDigits)
                .month(.wide)
                .locale(Locale(identifier: "ja_JP"))
        )
    }
}

#if DEBUG
#Preview("0件") {
    NavigationStack {
        MemoriesView(store: TicketStore(previewTickets: []), onCreateTicket: {})
    }
}

#Preview("1件") {
    NavigationStack {
        MemoriesView(
            store: TicketStore(previewTickets: [MemoryPreviewData.single]),
            onCreateTicket: {}
        )
    }
}

#Preview("複数・月またぎ") {
    NavigationStack {
        MemoriesView(
            store: TicketStore(previewTickets: MemoryPreviewData.multipleMonths),
            onCreateTicket: {}
        )
    }
}

#Preview("長文") {
    NavigationStack {
        MemoriesView(
            store: TicketStore(previewTickets: [MemoryPreviewData.longText]),
            onCreateTicket: {}
        )
    }
}

#Preview("Loading") {
    NavigationStack {
        MemoriesView(
            store: TicketStore(previewTickets: [], isReloadingCompleted: true),
            onCreateTicket: {}
        )
    }
}

#Preview("Error") {
    NavigationStack {
        MemoriesView(
            store: TicketStore(
                previewTickets: [],
                completionError: .ticketCompletionFailed
            ),
            onCreateTicket: {}
        )
    }
}

#Preview("Dark Mode") {
    NavigationStack {
        MemoriesView(
            store: TicketStore(previewTickets: MemoryPreviewData.multipleMonths),
            onCreateTicket: {}
        )
    }
    .preferredColorScheme(.dark)
}

#Preview("iPhone SE") {
    NavigationStack {
        MemoriesView(
            store: TicketStore(previewTickets: MemoryPreviewData.multipleMonths),
            onCreateTicket: {}
        )
    }
    .frame(width: 375, height: 667)
}
#endif
