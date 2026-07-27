import Foundation

enum AppDeepLink: Hashable, Sendable {
    case incomingFriendRequest(UUID)
    case friend(UUID)
    case receivedTicket(UUID)
    case sentTicket(UUID)
    case waitingTicket(UUID)
    case completedTicket(UUID)
}

enum DeepLinkTab: Sendable {
    case tickets
    case memories
    case profile
}

struct ResolvedDeepLink: Sendable {
    let link: AppDeepLink
    let tab: DeepLinkTab
}
