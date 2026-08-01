import Foundation
import Observation

/// Realtime購読を1ユーザー1接続に保ち、イベント後のStore再取得を調整するクラス
@MainActor
@Observable
final class RealtimeSyncCoordinator {
    private(set) var isConnected = false
    private(set) var isConnecting = false
    private(set) var lastConnectedAt: Date?
    private(set) var connectionError: AppError?

    @ObservationIgnored
    private let service: any RealtimeService
    @ObservationIgnored
    private let friendStore: FriendStore
    @ObservationIgnored
    private let ticketStore: TicketStore
    @ObservationIgnored
    private let notificationStore: NotificationStore
    @ObservationIgnored
    /// ユーザー切替時に旧Channelを確実に停止するための購読所有者
    private var subscribedUserID: UUID?
    @ObservationIgnored
    private var retryTask: Task<Void, Never>?
    @ObservationIgnored
    private var friendRefreshTask: Task<Void, Never>?
    @ObservationIgnored
    private var ticketRefreshTask: Task<Void, Never>?
    @ObservationIgnored
    private var notificationRefreshTask: Task<Void, Never>?

    init(
        service: any RealtimeService,
        friendStore: FriendStore,
        ticketStore: TicketStore,
        notificationStore: NotificationStore
    ) {
        self.service = service
        self.friendStore = friendStore
        self.ticketStore = ticketStore
        self.notificationStore = notificationStore
    }

    /// 同じユーザーの重複購読を避け、必要な場合だけChannelを開始する
    func start(userID: UUID) async {
        if subscribedUserID == userID, isConnected || isConnecting {
            return
        }

        if let subscribedUserID, subscribedUserID != userID {
            await stop()
        }

        retryTask?.cancel()
        subscribedUserID = userID
        await connect(userID: userID, attempt: 0)
    }

    func stop() async {
        subscribedUserID = nil
        retryTask?.cancel()
        retryTask = nil
        friendRefreshTask?.cancel()
        ticketRefreshTask?.cancel()
        notificationRefreshTask?.cancel()
        await service.stop()
        isConnected = false
        isConnecting = false
    }

    func resume(userID: UUID) async {
        if subscribedUserID == userID, isConnected {
            await refreshAll()
        } else {
            await start(userID: userID)
        }
    }

    func refreshAll() async {
        let friendsSucceeded = await friendStore.reloadFromRealtime()
        let ticketsSucceeded = await ticketStore.reloadFromRealtime()
        let notificationsSucceeded = await notificationStore.reloadFromRealtime()
        if !friendsSucceeded || !ticketsSucceeded || !notificationsSucceeded {
            connectionError = .realtimeRefreshFailed
        } else {
            connectionError = nil
        }
    }

    func retry() async {
        guard let userID = subscribedUserID else { return }
        await connect(userID: userID, attempt: 0)
    }

    private func connect(userID: UUID, attempt: Int) async {
        guard subscribedUserID == userID else { return }
        isConnecting = true
        connectionError = nil

        do {
            try await service.start(
                userID: userID,
                onEvent: { [weak self] event in
                    self?.receive(event)
                },
                onStatusChange: { [weak self] status in
                    self?.apply(status)
                }
            )
            isConnecting = false
            isConnected = true
            lastConnectedAt = .now
            await refreshAll()
        } catch {
            isConnecting = false
            isConnected = false
            connectionError = normalize(error)
            scheduleReconnect(userID: userID, attempt: attempt + 1)
        }
    }

    /// 接続失敗時に最大5回、1〜16秒の指数バックオフで再接続する
    private func scheduleReconnect(userID: UUID, attempt: Int) {
        guard attempt <= 5, subscribedUserID == userID else { return }
        retryTask?.cancel()
        let delay = min(pow(2, Double(attempt - 1)), 16)
        retryTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(delay))
            guard !Task.isCancelled, let self else { return }
            await connect(userID: userID, attempt: attempt)
        }
    }

    /// 連続イベントを180ミリ秒でまとめ、Repository再取得により最新状態へ収束させる
    private func receive(_ event: RealtimeEvent) {
        switch event.area {
        case .friends:
            friendRefreshTask?.cancel()
            friendRefreshTask = Task { [weak self] in
                try? await Task.sleep(for: .milliseconds(180))
                guard !Task.isCancelled, let self else { return }
                if !(await friendStore.reloadFromRealtime()) {
                    connectionError = .realtimeRefreshFailed
                }
            }
        case .tickets:
            ticketRefreshTask?.cancel()
            ticketRefreshTask = Task { [weak self] in
                try? await Task.sleep(for: .milliseconds(180))
                guard !Task.isCancelled, let self else { return }
                if !(await ticketStore.reloadFromRealtime()) {
                    connectionError = .realtimeRefreshFailed
                }
            }
        case .notifications:
            notificationRefreshTask?.cancel()
            notificationRefreshTask = Task { [weak self] in
                try? await Task.sleep(for: .milliseconds(180))
                guard !Task.isCancelled, let self else { return }
                if !(await notificationStore.reloadFromRealtime()) {
                    connectionError = .realtimeRefreshFailed
                }
            }
        }
    }

    private func apply(_ status: RealtimeConnectionStatus) {
        switch status {
        case .connected:
            isConnecting = false
            isConnected = true
            lastConnectedAt = .now
            connectionError = nil
        case .connecting:
            isConnecting = true
            isConnected = false
        case .disconnected:
            isConnecting = false
            isConnected = false
            if let subscribedUserID {
                scheduleReconnect(userID: subscribedUserID, attempt: 1)
            }
        }
    }

    private func normalize(_ error: Error) -> AppError {
        if let appError = error as? AppError { return appError }
        if error is URLError { return .realtimeNetworkDisconnected }
        return .realtimeConnectionFailed
    }
}
