import Foundation

@MainActor
protocol RealtimeService: AnyObject {
    var status: RealtimeConnectionStatus { get }
    var currentUserID: UUID? { get }

    func start(
        userID: UUID,
        onEvent: @escaping @MainActor @Sendable (RealtimeEvent) -> Void,
        onStatusChange: @escaping @MainActor @Sendable (RealtimeConnectionStatus) -> Void
    ) async throws

    func stop() async
}
