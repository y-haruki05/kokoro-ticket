import Foundation
import Observation

@MainActor
@Observable
final class FriendStore {
    private(set) var friends: [Friend]
    private(set) var incomingRequests: [FriendRequest]
    private(set) var outgoingRequests: [FriendRequest]
    private(set) var searchResult: FriendSearchResult?
    private(set) var hasSearched = false
    private(set) var isSearching = false
    private(set) var isLoading = false
    private(set) var error: AppError?
    private(set) var requestMessage: String?
    private(set) var processingRequestIDs: Set<UUID> = []
    private(set) var avatarDataByPath: [String: Data] = [:]
    private(set) var loadingAvatarPaths: Set<String> = []

    @ObservationIgnored
    private let repository: any FriendRepository

    init(
        repository: any FriendRepository,
        friends: [Friend] = [],
        incomingRequests: [FriendRequest] = [],
        outgoingRequests: [FriendRequest] = [],
        searchResult: FriendSearchResult? = nil,
        hasSearched: Bool = false,
        isSearching: Bool = false,
        isLoading: Bool = false,
        error: AppError? = nil
    ) {
        self.repository = repository
        self.friends = friends
        self.incomingRequests = incomingRequests
        self.outgoingRequests = outgoingRequests
        self.searchResult = searchResult
        self.hasSearched = hasSearched || searchResult != nil
        self.isSearching = isSearching
        self.isLoading = isLoading
        self.error = error
    }

    func reload() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            async let friends = repository.fetchFriends()
            async let incoming = repository.fetchIncomingRequests()
            async let outgoing = repository.fetchOutgoingRequests()
            (self.friends, incomingRequests, outgoingRequests) = try await (
                friends, incoming, outgoing
            )
            self.friends = unique(self.friends)
            incomingRequests = unique(incomingRequests)
            outgoingRequests = unique(outgoingRequests)
            error = nil
        } catch {
            self.error = normalize(error)
        }
    }

    func search(friendCode: String, currentProfile: Profile? = nil) async {
        guard !isSearching else { return }
        do {
            let code = try normalizeFriendCode(friendCode)
            hasSearched = true
            if let currentProfile, currentProfile.friendCode == code {
                searchResult = FriendSearchResult(
                    profile: FriendProfileSummary(
                        id: currentProfile.id,
                        displayName: currentProfile.displayName,
                        friendCode: currentProfile.friendCode,
                        avatarKey: currentProfile.avatarKey
                    ),
                    relationship: .selfProfile
                )
                error = nil
                return
            }
            isSearching = true
            defer { isSearching = false }
            searchResult = try await repository.searchProfile(friendCode: code)
            error = nil
        } catch {
            self.error = normalize(error)
        }
    }

    func sendRequest() async {
        guard !isLoading, let result = searchResult else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            try await repository.sendFriendRequest(receiverID: result.profile.id)
            searchResult = FriendSearchResult(
                profile: result.profile,
                relationship: .outgoingPending
            )
            outgoingRequests = try await repository.fetchOutgoingRequests()
            requestMessage = "フレンド申請を送りました"
            error = nil
        } catch {
            self.error = normalize(error)
        }
    }

    func accept(_ request: FriendRequest) async {
        await respond(request, accepts: true)
    }

    func reject(_ request: FriendRequest) async {
        await respond(request, accepts: false)
    }

    func clearError() {
        error = nil
    }

    func clearMessage() {
        requestMessage = nil
    }

    func clearSearch() {
        searchResult = nil
        hasSearched = false
    }

    func avatarData(for path: String?) -> Data? {
        guard let path else { return nil }
        return avatarDataByPath[path]
    }

    func loadAvatar(path: String?) async {
        guard
            let path,
            !path.isEmpty,
            avatarDataByPath[path] == nil,
            !loadingAvatarPaths.contains(path)
        else { return }

        loadingAvatarPaths.insert(path)
        defer { loadingAvatarPaths.remove(path) }
        do {
            avatarDataByPath[path] = try await repository.fetchAvatarData(path: path)
        } catch {
            // Avatar failures intentionally fall back to cat_default without
            // blocking friend operations.
        }
    }

    func isLoadingAvatar(path: String?) -> Bool {
        guard let path else { return false }
        return loadingAvatarPaths.contains(path)
    }

    @discardableResult
    func reloadFromRealtime() async -> Bool {
        var attempts = 0
        while isLoading, attempts < 5 {
            attempts += 1
            try? await Task.sleep(for: .milliseconds(120))
        }
        await reload()
        return error == nil
    }

    private func respond(_ request: FriendRequest, accepts: Bool) async {
        guard !processingRequestIDs.contains(request.id) else { return }
        processingRequestIDs.insert(request.id)
        defer { processingRequestIDs.remove(request.id) }
        do {
            if accepts {
                try await repository.acceptFriendRequest(id: request.id)
            } else {
                try await repository.rejectFriendRequest(id: request.id)
            }
            incomingRequests.removeAll { $0.id == request.id }
            if accepts {
                friends = try await repository.fetchFriends()
                requestMessage = "フレンドになりました"
            } else {
                requestMessage = "申請を拒否しました"
            }
            error = nil
        } catch {
            self.error = normalize(error)
        }
    }

    private func normalizeFriendCode(_ value: String) throws -> String {
        let normalized = value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()
        guard normalized.range(of: "^[A-HJ-NP-Z2-9]{8}$", options: .regularExpression) != nil else {
            throw AppError.invalidFriendCode
        }
        return normalized
    }

    private func normalize(_ error: Error) -> AppError {
        if let appError = error as? AppError { return appError }
        if let urlError = error as? URLError {
            return .network(description: urlError.localizedDescription)
        }
        return .friend(description: "フレンド情報の処理に失敗しました")
    }

    private func unique<Value: Identifiable>(_ values: [Value]) -> [Value]
    where Value.ID == UUID {
        var seen = Set<UUID>()
        return values.filter { seen.insert($0.id).inserted }
    }
}
