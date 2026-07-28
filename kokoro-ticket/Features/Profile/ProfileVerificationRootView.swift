#if DEBUG
import SwiftUI
import UIKit

@MainActor
struct ProfileVerificationRootView: View {
    var body: some View {
        if CommandLine.arguments.contains("-profile-edit") {
            ProfileDisplayNameEditView(
                store: profileStore,
                presentation: editPresentation
            )
        } else {
            ProfileView(
                store: profileStore,
                friendStore: FriendStore(
                    repository: InMemoryFriendRepository(
                        friends: MockFriends.items
                    )
                ),
                email: "kokoro@example.com",
                isAuthLoading: false,
                clipboard: PreviewClipboardService(),
                showsAvatarDeleteConfirmationInitially: CommandLine.arguments.contains(
                    "-profile-avatar-delete-confirmation"
                ),
                onLogout: {}
            )
        }
    }

    private var profileStore: ProfileStore {
        var profile: Profile? = CommandLine.arguments.contains("-profile-empty")
            ? nil
            : .preview
        let avatarData = Self.sampleAvatarData
        if CommandLine.arguments.contains("-profile-avatar-set"),
           var avatarProfile = profile {
            avatarProfile.avatarKey =
                "\(avatarProfile.id.uuidString.lowercased())/avatar-preview.jpg"
            profile = avatarProfile
        }
        return ProfileStore(
            repository: InMemoryProfileRepository(
                profile: profile,
                avatarData: avatarData
            ),
            profile: profile,
            isLoading: CommandLine.arguments.contains("-profile-loading"),
            error: CommandLine.arguments.contains("-profile-error")
                ? .profile(description: "プロフィールを読み込めませんでした")
                : nil,
            avatarData: CommandLine.arguments.contains("-profile-avatar-set")
                ? avatarData
                : nil,
            pendingAvatarData: CommandLine.arguments.contains("-profile-avatar-pending")
                ? avatarData
                : nil,
            isAvatarLoading: CommandLine.arguments.contains("-profile-avatar-loading"),
            isAvatarSaving: CommandLine.arguments.contains("-profile-avatar-saving"),
            avatarError: CommandLine.arguments.contains("-profile-avatar-error")
                ? .profileAvatarUploadFailed
                : nil,
            avatarFeedback: CommandLine.arguments.contains("-profile-avatar-success")
                ? .saved
                : nil
        )
    }

    private var editPresentation: ProfileEditPresentation {
        if CommandLine.arguments.contains("-profile-edit-saving") {
            return .saving
        }
        if CommandLine.arguments.contains("-profile-edit-success") {
            return .success
        }
        if CommandLine.arguments.contains("-profile-edit-failure") {
            return .failure
        }
        return .automatic
    }

    private static var sampleAvatarData: Data? {
        let renderer = UIGraphicsImageRenderer(
            size: CGSize(width: 320, height: 320)
        )
        return renderer.image { context in
            UIColor.systemTeal.setFill()
            context.cgContext.fill(
                CGRect(x: 0, y: 0, width: 320, height: 320)
            )
            let symbol = UIImage(
                systemName: "person.fill",
                withConfiguration: UIImage.SymbolConfiguration(pointSize: 150)
            )?.withTintColor(.white, renderingMode: .alwaysOriginal)
            symbol?.draw(
                in: CGRect(x: 85, y: 85, width: 150, height: 150)
            )
        }
        .jpegData(compressionQuality: 0.8)
    }
}
#endif
