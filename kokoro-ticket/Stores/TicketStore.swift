import Foundation
import Observation

@MainActor
@Observable
final class TicketStore {
    private(set) var tickets: [TicketListItem] = []
    private(set) var sentTickets: [TicketListItem] = []
    private(set) var receivedTickets: [TicketListItem] = []
    private(set) var isSending = false
    private(set) var sendError: AppError?
    private(set) var sendMessage: String?
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
        sendError: AppError? = nil
    ) {
        self.repository = repository
        self.localSenderName = localSenderName
        self.isSending = isSending
        self.sendError = sendError
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
    func requestUsage(id: UUID) -> Bool {
        perform {
            try repository.requestUsage(id: id, at: .now)
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
            (sentTickets, receivedTickets) = try await (sent, received)
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

    private func rebuildTickets() {
        var ticketsByID = Dictionary(
            uniqueKeysWithValues: localTickets.map { ($0.id, $0) }
        )
        for ticket in sentTickets + receivedTickets {
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
