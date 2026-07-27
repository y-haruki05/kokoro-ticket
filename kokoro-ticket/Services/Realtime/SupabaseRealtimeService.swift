import Foundation
import OSLog
import Supabase

@MainActor
final class SupabaseRealtimeService: RealtimeService {
    private(set) var status: RealtimeConnectionStatus = .disconnected
    private(set) var currentUserID: UUID?

    private let client: Supabase.SupabaseClient
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "kokoro-ticket",
        category: "Realtime"
    )
    private var channel: RealtimeChannelV2?
    private var listenerTasks: [Task<Void, Never>] = []

    init(clientProvider: any SupabaseClientProviding) {
        client = clientProvider.client
    }

    func start(
        userID: UUID,
        onEvent: @escaping @MainActor @Sendable (RealtimeEvent) -> Void,
        onStatusChange: @escaping @MainActor @Sendable (RealtimeConnectionStatus) -> Void
    ) async throws {
        if currentUserID == userID, status == .connected {
            return
        }

        await stop()
        currentUserID = userID
        updateStatus(.connecting, handler: onStatusChange)

        let channel = client.channel("kokoro-user-\(userID.uuidString)")
        self.channel = channel
        let userValue = userID.uuidString

        listen(
            channel.postgresChange(
                AnyAction.self,
                schema: "public",
                table: "friend_requests",
                filter: .eq("sender_id", value: userValue)
            ),
            event: RealtimeEvent(area: .friends, table: "friend_requests"),
            onEvent: onEvent
        )
        listen(
            channel.postgresChange(
                AnyAction.self,
                schema: "public",
                table: "notifications",
                filter: .eq("recipient_id", value: userValue)
            ),
            event: RealtimeEvent(area: .notifications, table: "notifications"),
            onEvent: onEvent
        )
        listen(
            channel.postgresChange(
                AnyAction.self,
                schema: "public",
                table: "friend_requests",
                filter: .eq("receiver_id", value: userValue)
            ),
            event: RealtimeEvent(area: .friends, table: "friend_requests"),
            onEvent: onEvent
        )
        listen(
            channel.postgresChange(
                AnyAction.self,
                schema: "public",
                table: "friendships",
                filter: .eq("user_id_low", value: userValue)
            ),
            event: RealtimeEvent(area: .friends, table: "friendships"),
            onEvent: onEvent
        )
        listen(
            channel.postgresChange(
                AnyAction.self,
                schema: "public",
                table: "friendships",
                filter: .eq("user_id_high", value: userValue)
            ),
            event: RealtimeEvent(area: .friends, table: "friendships"),
            onEvent: onEvent
        )
        listen(
            channel.postgresChange(
                AnyAction.self,
                schema: "public",
                table: "tickets",
                filter: .eq("owner_id", value: userValue)
            ),
            event: RealtimeEvent(area: .tickets, table: "tickets"),
            onEvent: onEvent
        )
        listen(
            channel.postgresChange(
                AnyAction.self,
                schema: "public",
                table: "ticket_transfers",
                filter: .eq("sender_id", value: userValue)
            ),
            event: RealtimeEvent(area: .tickets, table: "ticket_transfers"),
            onEvent: onEvent
        )
        listen(
            channel.postgresChange(
                AnyAction.self,
                schema: "public",
                table: "ticket_transfers",
                filter: .eq("receiver_id", value: userValue)
            ),
            event: RealtimeEvent(area: .tickets, table: "ticket_transfers"),
            onEvent: onEvent
        )
        listen(
            channel.postgresChange(
                AnyAction.self,
                schema: "public",
                table: "ticket_usage_requests",
                filter: .eq("requester_id", value: userValue)
            ),
            event: RealtimeEvent(area: .tickets, table: "ticket_usage_requests"),
            onEvent: onEvent
        )

        listenerTasks.append(
            Task { [weak self] in
                for await channelStatus in channel.statusChange {
                    guard !Task.isCancelled, let self else { return }
                    switch channelStatus {
                    case .subscribed:
                        updateStatus(.connected, handler: onStatusChange)
                    case .subscribing:
                        updateStatus(.connecting, handler: onStatusChange)
                    case .unsubscribed, .unsubscribing:
                        updateStatus(.disconnected, handler: onStatusChange)
                    }
                }
            }
        )

        do {
            try await channel.subscribeWithError()
            updateStatus(.connected, handler: onStatusChange)
            logger.info("Realtime subscription connected")
        } catch {
            logger.error("Realtime subscription failed: \(String(describing: type(of: error)), privacy: .public)")
            await stop()
            throw AppError.realtimeSubscriptionFailed
        }
    }

    func stop() async {
        listenerTasks.forEach { $0.cancel() }
        listenerTasks.removeAll()
        if let channel {
            await client.removeChannel(channel)
        }
        channel = nil
        currentUserID = nil
        status = .disconnected
        logger.info("Realtime subscription stopped")
    }

    private func listen<Action: Sendable>(
        _ stream: AsyncStream<Action>,
        event: RealtimeEvent,
        onEvent: @escaping @MainActor @Sendable (RealtimeEvent) -> Void
    ) {
        listenerTasks.append(
            Task {
                for await _ in stream {
                    guard !Task.isCancelled else { return }
                    onEvent(event)
                }
            }
        )
    }

    private func updateStatus(
        _ status: RealtimeConnectionStatus,
        handler: @escaping @MainActor @Sendable (RealtimeConnectionStatus) -> Void
    ) {
        self.status = status
        handler(status)
    }
}
