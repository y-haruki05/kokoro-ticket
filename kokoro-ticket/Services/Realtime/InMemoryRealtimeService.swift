import Foundation

/// Previewとテストで接続状態やイベント配信を再現するRealtime実装
@MainActor
final class InMemoryRealtimeService: RealtimeService {
    private(set) var status: RealtimeConnectionStatus
    private(set) var currentUserID: UUID?
    var startError: AppError?

    private var eventHandler: (@MainActor @Sendable (RealtimeEvent) -> Void)?
    private var statusHandler: (@MainActor @Sendable (RealtimeConnectionStatus) -> Void)?

    init(
        status: RealtimeConnectionStatus = .disconnected,
        startError: AppError? = nil
    ) {
        self.status = status
        self.startError = startError
    }

    func start(
        userID: UUID,
        onEvent: @escaping @MainActor @Sendable (RealtimeEvent) -> Void,
        onStatusChange: @escaping @MainActor @Sendable (RealtimeConnectionStatus) -> Void
    ) async throws {
        if let startError { throw startError }
        currentUserID = userID
        eventHandler = onEvent
        statusHandler = onStatusChange
        status = .connected
        onStatusChange(.connected)
    }

    func stop() async {
        currentUserID = nil
        eventHandler = nil
        statusHandler = nil
        status = .disconnected
    }

    func emit(_ event: RealtimeEvent) {
        eventHandler?(event)
    }

    func simulateDisconnect() {
        status = .disconnected
        statusHandler?(.disconnected)
    }
}
