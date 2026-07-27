#if DEBUG
import SwiftUI

@MainActor
struct HomeVerificationRootView: View {
    private let profile = Profile(
        id: UUID(),
        displayName: "山本",
        friendCode: "KRTK7M2P",
        avatarKey: nil,
        createdAt: .now,
        updatedAt: .now
    )

    var body: some View {
        MainTabView(
            repository: InMemoryTicketRepository(
                tickets: HomePreviewData.normalTickets.map(Ticket.init(item:))
            ),
            friendRepository: InMemoryFriendRepository(),
            notificationRepository: InMemoryNotificationRepository(
                notifications: NotificationPreviewData.allTypes
            ),
            profileStore: ProfileStore(
                repository: InMemoryProfileRepository(profile: profile),
                profile: profile,
                isLoading: false
            )
        )
    }
}
#endif
