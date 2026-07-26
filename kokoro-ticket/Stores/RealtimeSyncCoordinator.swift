import Foundation
import Observation

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
    private var subscribedUserID: UUID?
    @ObservationIgnored
    private var retryTask: Task<Void, Never>?
    @ObservationIgnored
    private var friendRefreshTask: Task<Void, Never>?
    @ObservationIgnored
    private var ticketRefreshTask: Task<Void, Never>?

    init(
        service: any RealtimeService,
        friendStore: FriendStore,
        ticketStore: TicketStore
    ) {
        self.service = service
        self.friendStore = friendStore
        self.ticketStore = ticketStore
    }

    func start(userID: UUID) async {
        guard subscribedUserID != userID || !isConnected else {
            await refreshAll()
            return
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
        await service.stop()
        isConnected = false
        isConnecting = false
    }

    func resume(userID: UUID) async {
        await start(userID: userID)
        await refreshAll()
    }

    func refreshAll() async {
        let friendsSucceeded = await friendStore.reloadFromRealtime()
        let ticketsSucceeded = await ticketStore.reloadFromRealtime()
        if !friendsSucceeded || !ticketsSucceeded {
            connectionError = .realtimeRefreshFailed
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
