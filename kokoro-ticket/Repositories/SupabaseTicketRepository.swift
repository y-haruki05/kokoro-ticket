import Foundation
import OSLog
import Supabase

/// SwiftDataの下書きとSupabase RPCによる送受信状態を橋渡しするRepository
@MainActor
final class SupabaseTicketRepository: TicketRepository {
    private let localRepository: SwiftDataTicketRepository
    private let client: Supabase.SupabaseClient
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "kokoro-ticket",
        category: "TicketRepository"
    )

    init(
        localRepository: SwiftDataTicketRepository,
        clientProvider: any SupabaseClientProviding
    ) {
        self.localRepository = localRepository
        client = clientProvider.client
    }

    func fetchAll() throws -> [Ticket] {
        try localRepository.fetchAll()
    }

    func insert(_ ticket: Ticket) throws {
        try localRepository.insert(ticket)
    }

    func updateDraft(id: UUID, title: String, message: String, at updatedAt: Date) throws {
        try localRepository.updateDraft(id: id, title: title, message: message, at: updatedAt)
    }

    func deleteDraft(id: UUID) throws {
        try localRepository.deleteDraft(id: id)
    }

    func send(id: UUID, to friend: Friend, at sentAt: Date) throws {
        try localRepository.send(id: id, to: friend, at: sentAt)
    }

    func receive(id: UUID, at receivedAt: Date) throws {
        try localRepository.receive(id: id, at: receivedAt)
    }

    func requestUsage(id: UUID, at requestedAt: Date) throws {
        try localRepository.requestUsage(id: id, at: requestedAt)
    }

    func complete(id: UUID, at completedAt: Date) throws {
        try localRepository.complete(id: id, at: completedAt)
    }

    /// 下書きを同期した後、RPC内の同一トランザクションで送信を確定する
    func sendTicket(
        _ ticket: TicketListItem,
        to friend: Friend,
        at sentAt: Date
    ) async throws -> TicketTransfer {
        guard ticket.status == .draft else {
            throw AppError.ticketNotDraft
        }
        guard friend.id != client.auth.currentUser?.id else {
            throw AppError.ticketSendToSelf
        }

        do {
            try await persistDraft(ticket)
            let records: [TicketTransferRecord] = try await client
                .rpc(
                    "send_ticket",
                    params: [
                        "target_ticket_id": ticket.id.uuidString,
                        "target_receiver_id": friend.id.uuidString
                    ]
                )
                .execute()
                .value
            guard let record = records.first else {
                throw AppError.ticketTransfer(description: "送信結果を確認できませんでした")
            }

            try localRepository.send(id: ticket.id, to: friend, at: record.sentAt)
            return TicketTransfer(record: record)
        } catch {
            throw map(error, action: "チケット送信")
        }
    }

    func getSentTickets() async throws -> [TicketListItem] {
        try await fetchRemoteTickets(function: "get_sent_tickets", perspective: .sender)
    }

    func getReceivedTickets() async throws -> [TicketListItem] {
        try await fetchRemoteTickets(function: "get_received_tickets", perspective: .receiver)
    }

    func acknowledgeTicket(id: UUID) async throws {
        do {
            let result: String = try await client
                .rpc("acknowledge_ticket", params: ["target_ticket_id": id.uuidString])
                .execute()
                .value
            guard result == TicketStatus.received.rawValue else {
                throw AppError.ticketAcknowledgementFailed
            }
        } catch {
            throw map(error, action: "チケット受取確認")
        }
    }

    func requestTicketUsage(id: UUID) async throws -> TicketUsageRequest {
        do {
            let records: [TicketUsageRequestRecord] = try await client
                .rpc("request_ticket_usage", params: ["target_ticket_id": id.uuidString])
                .execute()
                .value
            guard let record = records.first else {
                throw AppError.ticketUsageRequestFailed
            }
            return TicketUsageRequest(record: record)
        } catch {
            throw map(error, action: "使用リクエスト")
        }
    }

    func getRequestedTickets() async throws -> [TicketListItem] {
        try await fetchRemoteTickets(function: "get_requested_tickets", perspective: .receiver)
    }

    func getWaitingTickets() async throws -> [TicketListItem] {
        try await fetchRemoteTickets(function: "get_waiting_tickets", perspective: .sender)
    }

    func completeTicket(id: UUID) async throws {
        do {
            let result: String = try await client
                .rpc("complete_ticket", params: ["target_ticket_id": id.uuidString])
                .execute()
                .value
            guard result == TicketStatus.completed.rawValue else {
                throw AppError.ticketCompletionFailed
            }
        } catch {
            throw map(error, action: "チケット完了")
        }
    }

    func getCompletedTickets() async throws -> [TicketListItem] {
        try await fetchRemoteTickets(function: "get_completed_tickets", perspective: .local)
    }

    /// RPCが所有者とdraft状態を検証できるよう、送信対象の内容を先に同期する
    private func persistDraft(_ ticket: TicketListItem) async throws {
        guard let ownerID = client.auth.currentUser?.id else {
            throw AppError.authenticatedUserUnavailable
        }
        let payload = RemoteTicketDraft(
            id: ticket.id,
            ownerID: ownerID,
            ticketTitle: ticket.title,
            message: ticket.message,
            illustration: ticket.illustration?.id,
            backgroundColor: ticket.design.backgroundColor.rawValue,
            borderStyle: ticket.design.borderStyle.rawValue,
            status: TicketStatus.draft.rawValue,
            createdAt: ticket.createdAt,
            updatedAt: ticket.updatedAt
        )
        try await client
            .from("tickets")
            .upsert(payload, onConflict: "id")
            .execute()
    }

    private func fetchRemoteTickets(
        function: String,
        perspective: TicketPerspective
    ) async throws -> [TicketListItem] {
        do {
            let records: [RemoteTicketRecord] = try await client
                .rpc(function)
                .execute()
                .value
            return records.map { TicketListItem(record: $0, perspective: perspective) }
        } catch {
            throw map(error, action: "チケット一覧取得")
        }
    }

    /// RPCが返すエラーコードを画面表示用のAppErrorへ分類する
    private func map(_ error: Error, action: String) -> AppError {
        if let appError = error as? AppError { return appError }
        if let urlError = networkError(from: error) {
            return .network(description: urlError.localizedDescription)
        }

        let description = String(reflecting: error).lowercased()
        logger.error("\(action, privacy: .public) failed: \(String(describing: type(of: error)), privacy: .public)")
        if description.contains("ticket_not_draft") { return .ticketNotDraft }
        if description.contains("ticket_not_owned") { return .ticketNotOwned }
        if description.contains("receiver_not_friend") { return .ticketReceiverNotFriend }
        if description.contains("self_transfer") { return .ticketSendToSelf }
        if description.contains("already_transferred") || description.contains("23505") {
            return .ticketAlreadySent
        }
        if description.contains("receiver_only") { return .ticketReceiverOnly }
        if description.contains("ticket_not_sent") { return .ticketNotSent }
        if description.contains("ticket_not_received") { return .ticketNotReceived }
        if description.contains("already_requested") { return .ticketUsageAlreadyRequested }
        if description.contains("sender_only") { return .ticketSenderOnly }
        if description.contains("already_completed") { return .ticketAlreadyCompleted }
        if description.contains("ticket_not_requested") { return .ticketNotRequested }
        if description.contains("usage_request_not_found") {
            return .ticketUsageRequestNotFound
        }
        if description.contains("ticket_not_found") {
            return .ticketTransfer(description: "チケットが見つかりません")
        }
        if description.contains("42501") || description.contains("permission") {
            return .ticketPermissionDenied
        }
        return .ticketTransfer(description: "\(action)に失敗しました")
    }

    private func networkError(from error: Error) -> URLError? {
        if let urlError = error as? URLError { return urlError }
        return (error as NSError).userInfo[NSUnderlyingErrorKey] as? URLError
    }
}

private struct RemoteTicketDraft: Encodable {
    let id: UUID
    let ownerID: UUID
    let ticketTitle: String
    let message: String
    let illustration: String?
    let backgroundColor: String
    let borderStyle: String
    let status: String
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case ownerID = "owner_id"
        case ticketTitle = "ticket_title"
        case message, illustration
        case backgroundColor = "background_color"
        case borderStyle = "border_style"
        case status
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

private struct TicketTransferRecord: Decodable {
    let id: UUID
    let ticketID: UUID
    let senderID: UUID
    let receiverID: UUID
    let senderNameSnapshot: String
    let receiverNameSnapshot: String
    let sentAt: Date
    let receivedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case ticketID = "ticket_id"
        case senderID = "sender_id"
        case receiverID = "receiver_id"
        case senderNameSnapshot = "sender_name_snapshot"
        case receiverNameSnapshot = "receiver_name_snapshot"
        case sentAt = "sent_at"
        case receivedAt = "received_at"
    }
}

private struct RemoteTicketRecord: Decodable {
    let id: UUID
    let ticketTitle: String
    let message: String
    let illustration: String?
    let backgroundColor: String
    let borderStyle: String
    let createdAt: Date
    let updatedAt: Date
    let sentAt: Date?
    let receivedAt: Date?
    let requestedAt: Date?
    let completedAt: Date?
    let status: TicketStatus
    let senderName: String
    let receiverName: String

    enum CodingKeys: String, CodingKey {
        case id
        case ticketTitle = "ticket_title"
        case message, illustration
        case backgroundColor = "background_color"
        case borderStyle = "border_style"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case sentAt = "sent_at"
        case receivedAt = "received_at"
        case requestedAt = "requested_at"
        case completedAt = "completed_at"
        case status
        case senderName = "sender_name"
        case receiverName = "receiver_name"
    }
}

private struct TicketUsageRequestRecord: Decodable {
    let id: UUID
    let ticketID: UUID
    let requesterID: UUID
    let requestedAt: Date
    let completedBy: UUID?
    let completedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case ticketID = "ticket_id"
        case requesterID = "requester_id"
        case requestedAt = "requested_at"
        case completedBy = "completed_by"
        case completedAt = "completed_at"
    }
}

private extension TicketTransfer {
    init(record: TicketTransferRecord) {
        self.init(
            id: record.id,
            ticketID: record.ticketID,
            senderID: record.senderID,
            receiverID: record.receiverID,
            senderNameSnapshot: record.senderNameSnapshot,
            receiverNameSnapshot: record.receiverNameSnapshot,
            sentAt: record.sentAt,
            receivedAt: record.receivedAt
        )
    }
}

private extension TicketListItem {
    init(record: RemoteTicketRecord, perspective: TicketPerspective) {
        self.init(
            id: record.id,
            illustration: record.illustration.map(TicketIllustration.init(id:)),
            title: record.ticketTitle,
            message: record.message,
            senderName: record.senderName,
            receiverName: record.receiverName,
            createdAt: record.createdAt,
            updatedAt: record.updatedAt,
            sentAt: record.sentAt,
            receivedAt: record.receivedAt,
            requestedAt: record.requestedAt,
            completedAt: record.completedAt,
            status: record.status,
            perspective: perspective,
            design: TicketDesign(
                backgroundColor: TicketBackgroundColor(rawValue: record.backgroundColor) ?? .white,
                borderStyle: TicketBorderStyle(rawValue: record.borderStyle) ?? .simple
            )
        )
    }
}

private extension TicketUsageRequest {
    init(record: TicketUsageRequestRecord) {
        self.init(
            id: record.id,
            ticketID: record.ticketID,
            requesterID: record.requesterID,
            requestedAt: record.requestedAt,
            completedBy: record.completedBy,
            completedAt: record.completedAt
        )
    }
}
