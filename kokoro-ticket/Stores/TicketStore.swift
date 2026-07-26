import Foundation
import Observation

@MainActor
@Observable
final class TicketStore {
    private(set) var tickets: [TicketListItem] = []
    private(set) var sentTickets: [TicketListItem] = []
    private(set) var receivedTickets: [TicketListItem] = []
    private(set) var requestedTickets: [TicketListItem] = []
    private(set) var waitingTickets: [TicketListItem] = []
    private(set) var isSending = false
    private(set) var isRequesting = false
    private(set) var sendError: AppError?
    private(set) var sendMessage: String?
    private(set) var requestError: AppError?
    private(set) var requestMessage: String?
    private(set) var lastErrorMessage: String?

    private var localTickets: [TicketListItem] = []

    @ObservationIgnored
    private let repository: any TicketRepository

    @ObservationIgnored
    private let localSenderName: String

    init(
        repository: any TicketRepository,
        localSenderName: String = "ゆうせい",
        isSending: Bool = false,
        sendError: AppError? = nil,
        isRequesting: Bool = false,
        requestError: AppError? = nil
    ) {
        self.repository = repository
        self.localSenderName = localSenderName
        self.isSending = isSending
        self.sendError = sendError
        self.isRequesting = isRequesting
        self.requestError = requestError
        reload()
    }

    convenience init(tickets: [TicketListItem] = []) {
        self.init(
            repository: InMemoryTicketRepository(
                tickets: tickets.map(Ticket.init(item:))
            )
        )
    }

    func tickets(for status: TicketStatus) -> [TicketListItem] {
        let source: [TicketListItem]
        switch status {
        case .sent:
            source = sentTickets
        case .received:
            source = receivedTickets
        case .requested:
            source = requestedTickets + waitingTickets
        default:
            source = tickets.filter { $0.status == status }
        }
        return source
            .sorted { $0.updatedAt > $1.updatedAt }
    }

    func ticket(id: TicketListItem.ID) -> TicketListItem? {
        tickets.first { $0.id == id }
    }

    @discardableResult
    func add(
        savedTicket: TicketCreationDraftSnapshot,
        createdAt: Date = .now
    ) -> Bool {
        perform {
            try repository.insert(
                Ticket(
                    savedTicket: savedTicket,
                    senderName: localSenderName,
                    createdAt: createdAt
                )
            )
        }
    }

    @discardableResult
    func updateDraft(id: UUID, title: String, message: String) -> Bool {
        perform {
            try repository.updateDraft(
                id: id,
                title: title,
                message: message,
                at: .now
            )
        }
    }

    @discardableResult
    func deleteDraft(id: UUID) -> Bool {
        perform {
            try repository.deleteDraft(id: id)
        }
    }

    @discardableResult
    func send(id: UUID, to friend: Friend) -> Bool {
        perform {
            try repository.send(id: id, to: friend, at: .now)
        }
    }

    @discardableResult
    func sendTicket(id: UUID, to friend: Friend) async -> Bool {
        guard !isSending, let ticket = ticket(id: id), ticket.status == .draft else {
            if ticket(id: id)?.status != .draft {
                sendError = .ticketNotDraft
            }
            return false
        }

        isSending = true
        sendError = nil
        defer { isSending = false }

        do {
            _ = try await repository.sendTicket(ticket, to: friend, at: .now)
            reload()
            await reloadRemoteTickets()
            sendMessage = "\(friend.displayName)さんへ送りました"
            return true
        } catch {
            sendError = normalizedSendError(error)
            return false
        }
    }

    @discardableResult
    func receive(id: UUID) -> Bool {
        perform {
            try repository.receive(id: id, at: .now)
        }
    }

    @discardableResult
    func requestUsageLocally(id: UUID) -> Bool {
        perform {
            try repository.requestUsage(id: id, at: .now)
        }
    }

    @discardableResult
    func acknowledgeTicket(id: UUID) async -> Bool {
        guard !isRequesting else { return false }
        isRequesting = true
        requestError = nil
        defer { isRequesting = false }

        do {
            try await repository.acknowledgeTicket(id: id)
            await reloadRemoteTickets()
            requestMessage = "受け取りました"
            return true
        } catch {
            requestError = normalizedRequestError(error)
            return false
        }
    }

    @discardableResult
    func requestUsage(id: UUID) async -> Bool {
        guard !isRequesting else { return false }
        isRequesting = true
        requestError = nil
        defer { isRequesting = false }

        do {
            _ = try await repository.requestTicketUsage(id: id)
            await reloadRemoteTickets()
            requestMessage = "使用リクエストを送りました"
            return true
        } catch {
            requestError = normalizedRequestError(error)
            return false
        }
    }

    @discardableResult
    func complete(id: UUID) -> Bool {
        perform {
            try repository.complete(id: id, at: .now)
        }
    }

    func reload() {
        do {
            localTickets = try repository.fetchAll().map(TicketListItem.init(ticket:))
            rebuildTickets()
            lastErrorMessage = nil
        } catch {
            lastErrorMessage = "チケットの読み込みに失敗しました"
        }
    }

    func reloadRemoteTickets() async {
        do {
            async let sent = repository.getSentTickets()
            async let received = repository.getReceivedTickets()
            async let requested = repository.getRequestedTickets()
            async let waiting = repository.getWaitingTickets()
            (sentTickets, receivedTickets, requestedTickets, waitingTickets) =
                try await (sent, received, requested, waiting)
            rebuildTickets()
        } catch {
            sendError = normalizedSendError(error)
        }
    }

    func clearSendError() {
        sendError = nil
    }

    func clearSendMessage() {
        sendMessage = nil
    }

    func clearRequestError() {
        requestError = nil
    }

    func clearRequestMessage() {
        requestMessage = nil
    }

    private func rebuildTickets() {
        var ticketsByID = Dictionary(
            uniqueKeysWithValues: localTickets.map { ($0.id, $0) }
        )
        for ticket in sentTickets + receivedTickets + requestedTickets + waitingTickets {
            ticketsByID[ticket.id] = ticket
        }
        tickets = Array(ticketsByID.values)
    }

    private func normalizedSendError(_ error: Error) -> AppError {
        if let appError = error as? AppError { return appError }
        if let repositoryError = error as? TicketRepositoryError {
            switch repositoryError {
            case .ticketNotFound:
                return .ticketTransfer(description: "チケットが見つかりません")
            case .invalidTransition:
                return .ticketNotDraft
            case .remoteUnavailable:
                return .ticketTransfer(description: "送信機能を利用できません")
            }
        }
        if let urlError = error as? URLError {
            return .network(description: urlError.localizedDescription)
        }
        return .ticketTransfer(description: "チケットを送信できませんでした")
    }

    private func normalizedRequestError(_ error: Error) -> AppError {
        if let appError = error as? AppError { return appError }
        if let urlError = error as? URLError {
            return .network(description: urlError.localizedDescription)
        }
        return .ticketTransfer(description: "チケットの状態を更新できませんでした")
    }

    @discardableResult
    private func perform(_ operation: () throws -> Void) -> Bool {
        do {
            try operation()
            reload()
            return true
        } catch {
            lastErrorMessage = "チケットを更新できませんでした"
            return false
        }
    }
}
