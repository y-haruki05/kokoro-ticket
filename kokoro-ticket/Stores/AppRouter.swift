import Foundation
import Observation

/// 通知のリソースを検証し、表示可能なタブと詳細画面へ解決するルーター
@MainActor
@Observable
final class AppRouter {
    private(set) var isResolvingDeepLink = false
    private(set) var deepLinkError: AppError?
    private(set) var resolvingNotificationID: UUID?
    private(set) var fallbackTab: DeepLinkTab?
    @ObservationIgnored private var lastResolvedLink: AppDeepLink?

    /// 対応データをStoreから再取得し、安全に表示できる遷移先を決定する
    func resolve(
        notification: AppNotification,
        friendStore: FriendStore,
        ticketStore: TicketStore
    ) async -> ResolvedDeepLink? {
        guard !isResolvingDeepLink, resolvingNotificationID != notification.id else { return nil }
        isResolvingDeepLink = true
        resolvingNotificationID = notification.id
        defer {
            isResolvingDeepLink = false
            resolvingNotificationID = nil
        }

        do {
            let link = try AppDeepLinkMapper.map(notification)
            fallbackTab = tab(for: link)
            let result = try await validate(
                link,
                friendStore: friendStore,
                ticketStore: ticketStore
            )
            guard lastResolvedLink != link else { return nil }
            lastResolvedLink = link
            deepLinkError = nil
            return result
        } catch {
            deepLinkError = error as? AppError ?? .deepLinkTargetUnavailable
            return nil
        }
    }

    func allowRetry() {
        lastResolvedLink = nil
    }

    func clearError() {
        deepLinkError = nil
    }

    private func tab(for link: AppDeepLink) -> DeepLinkTab {
        switch link {
        case .incomingFriendRequest, .friend: .profile
        case .receivedTicket, .sentTicket, .waitingTicket: .tickets
        case .completedTicket: .memories
        }
    }

    private func validate(
        _ link: AppDeepLink,
        friendStore: FriendStore,
        ticketStore: TicketStore
    ) async throws -> ResolvedDeepLink {
        switch link {
        case let .incomingFriendRequest(id):
            await friendStore.reload()
            guard friendStore.incomingRequests.contains(where: { $0.id == id }) else {
                throw AppError.deepLinkTargetUnavailable
            }
            return ResolvedDeepLink(link: link, tab: .profile)
        case let .friend(id):
            await friendStore.reload()
            guard friendStore.friends.contains(where: { $0.id == id }) else {
                throw AppError.deepLinkTargetUnavailable
            }
            return ResolvedDeepLink(link: link, tab: .profile)
        case let .receivedTicket(id), let .sentTicket(id), let .waitingTicket(id):
            guard await ticketStore.reloadFromRealtime(), ticketStore.ticket(id: id) != nil else {
                throw AppError.deepLinkTargetUnavailable
            }
            return ResolvedDeepLink(link: link, tab: .tickets)
        case let .completedTicket(id):
            guard await ticketStore.reloadFromRealtime(),
                  ticketStore.ticket(id: id)?.status == .completed else {
                throw AppError.deepLinkTargetUnavailable
            }
            return ResolvedDeepLink(link: link, tab: .memories)
        }
    }
}
