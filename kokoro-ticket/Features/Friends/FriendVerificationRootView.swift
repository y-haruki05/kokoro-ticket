#if DEBUG
import SwiftUI

@MainActor
struct FriendVerificationRootView: View {
    private let store: FriendStore

    init() {
        let arguments = CommandLine.arguments
        let repository = InMemoryFriendRepository(
            currentUserID: FriendPreviewData.currentUserID,
            profiles: [
                FriendPreviewData.currentProfile,
                FriendPreviewData.otherProfile
            ],
            requests: [
                FriendPreviewData.incomingRequest,
                FriendPreviewData.outgoingRequest
            ],
            friends: FriendPreviewData.friends
        )
        if arguments.contains("-friends-empty") {
            store = FriendStore(repository: InMemoryFriendRepository())
        } else if arguments.contains("-friends-loading") {
            store = FriendStore(
                repository: InMemoryFriendRepository(),
                isLoading: true
            )
        } else if arguments.contains("-friends-error") {
            store = FriendStore(
                repository: InMemoryFriendRepository(),
                error: .network(description: "通信環境を確認してください")
            )
        } else {
            store = FriendStore(
                repository: repository,
                friends: FriendPreviewData.friends,
                incomingRequests: [FriendPreviewData.incomingRequest],
                outgoingRequests: [FriendPreviewData.outgoingRequest],
                searchResult: arguments.contains("-friends-search-empty")
                    ? nil
                    : FriendPreviewData.searchResult,
                hasSearched: arguments.contains("-friends-search-empty")
                    || arguments.contains("-friends-search")
            )
        }
    }

    var body: some View {
        NavigationStack {
            if CommandLine.arguments.contains("-friends-search")
                || CommandLine.arguments.contains("-friends-search-empty") {
                FriendSearchView(store: store, currentProfile: .preview)
            } else if CommandLine.arguments.contains("-friends-incoming") {
                IncomingFriendRequestsView(store: store)
            } else if CommandLine.arguments.contains("-friends-outgoing") {
                OutgoingFriendRequestsView(store: store)
            } else {
                FriendListView(
                    store: store,
                    profile: .preview,
                    clipboard: PreviewClipboardService(),
                    loadsRemoteData: false
                )
            }
        }
    }
}
#endif
