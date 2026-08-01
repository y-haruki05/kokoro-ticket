import Foundation

/// Supabase RealtimeとInMemory実装を差し替えるための購読インターフェース
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
