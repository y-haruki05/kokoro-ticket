import SwiftUI

struct NotificationListView: View {
    let store: NotificationStore
    var isResolvingDeepLink = false
    var onOpen: (AppNotification) async -> Void = { _ in }

    var body: some View {
        Group {
            if store.isLoading && store.notifications.isEmpty {
                AppLoadingView(message: "通知を読み込んでいます")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if store.notifications.isEmpty {
                emptyView
            } else {
                list
            }
        }
        .background(AppColors.background.ignoresSafeArea())
        .navigationTitle("通知")
        .navigationBarTitleDisplayMode(.inline)
        .appNavigationStyle()
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("すべて既読") {
                    Task { await store.markAllAsRead() }
                }
                .font(.system(size: 14, weight: .semibold))
                .disabled(store.unreadCount == 0 || store.isMarkingAllRead)
            }
        }
        .task { await store.reload() }
        .refreshable { await store.reload() }
        .alert(
            "通知を更新できませんでした",
            isPresented: Binding(
                get: { store.error != nil || store.readError != nil },
                set: { if !$0 { store.clearError() } }
            )
        ) {
            Button("OK") { store.clearError() }
        } message: {
            Text((store.readError ?? store.error)?.localizedDescription ?? "")
        }
    }

    private var list: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(store.notifications) { notification in
                    Button {
                        Task {
                            await store.markAsRead(notification)
                            await onOpen(notification)
                        }
                    } label: {
                        NotificationRow(notification: notification)
                    }
                    .buttonStyle(.plain)
                    .disabled(isResolvingDeepLink)
                    .task { await store.loadMoreIfNeeded(current: notification) }
                }
                if store.isLoadingMore {
                    ProgressView().tint(AppColors.primary).padding()
                }
            }
            .padding(20)
            .padding(.bottom, 80)
        }
        .overlay {
            if isResolvingDeepLink {
                ZStack {
                    Color.black.opacity(0.08).ignoresSafeArea()
                    ProgressView("読み込み中")
                        .padding(20)
                        .background(AppColors.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                }
            }
        }
    }

    private var emptyView: some View {
        AppEmptyStateView(
            imageName: "cat_welcome",
            title: "まだ通知はありません",
            message: "新しいお知らせが届くと、ここに表示されます"
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct NotificationRow: View {
    let notification: AppNotification

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: notification.type.iconName)
                .font(.system(size: 19, weight: .semibold))
                .foregroundStyle(AppColors.primaryDark)
                .frame(width: 42, height: 42)
                .background(AppColors.primarySoft)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 5) {
                HStack(alignment: .firstTextBaseline) {
                    Text(notification.title)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(AppColors.textPrimary)
                    Spacer()
                    if !notification.isRead {
                        Circle().fill(AppColors.primary).frame(width: 8, height: 8)
                    }
                }
                Text(notification.message)
                    .font(.system(size: 14, design: .rounded))
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.leading)
                HStack {
                    if let actor = notification.actorDisplayName {
                        Text(actor)
                    }
                    Spacer()
                    Text(notification.createdAt, format: .dateTime.month().day().hour().minute())
                }
                .font(.system(size: 12, design: .rounded))
                .foregroundStyle(AppColors.textSecondary.opacity(0.8))
            }
        }
        .padding(16)
        .background(notification.isRead ? AppColors.cardBackground : AppColors.primarySoft)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .stroke(AppColors.border.opacity(0.8), lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityValue(notification.isRead ? "既読" : "未読")
    }
}

#Preview("未読・全種別") {
    NavigationStack {
        NotificationListView(
            store: NotificationStore(
                repository: InMemoryNotificationRepository(
                    notifications: NotificationPreviewData.allTypes
                ),
                notifications: NotificationPreviewData.allTypes,
                unreadCount: 3
            )
        )
    }
}

#Preview("通知0件") {
    NavigationStack {
        NotificationListView(
            store: NotificationStore(repository: InMemoryNotificationRepository())
        )
    }
}

#Preview("20件以上") {
    NavigationStack {
        NotificationListView(
            store: NotificationStore(
                repository: InMemoryNotificationRepository(
                    notifications: NotificationPreviewData.many
                ),
                notifications: Array(NotificationPreviewData.many.prefix(20)),
                unreadCount: 16
            )
        )
    }
}

#Preview("すべて既読") {
    let read = NotificationPreviewData.allTypes.map {
        var value = $0
        value.readAt = .now
        return value
    }
    NavigationStack {
        NotificationListView(
            store: NotificationStore(
                repository: InMemoryNotificationRepository(notifications: read),
                notifications: read
            )
        )
    }
}

#Preview("エラー") {
    NavigationStack {
        NotificationListView(
            store: NotificationStore(
                repository: InMemoryNotificationRepository(
                    error: .notificationFetchFailed
                )
            )
        )
    }
}

#Preview("Deep Link取得中") {
    NavigationStack {
        NotificationListView(
            store: NotificationStore(
                repository: InMemoryNotificationRepository(
                    notifications: NotificationPreviewData.allTypes
                ),
                notifications: NotificationPreviewData.allTypes,
                unreadCount: 3
            ),
            isResolvingDeepLink: true
        )
    }
}
