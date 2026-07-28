import SwiftUI
import UIKit

struct FriendAvatarView: View {
    let imageData: Data?
    var isLoading = false
    var size: CGFloat = 64

    var body: some View {
        ZStack {
            Circle()
                .fill(AppColors.primarySoft)

            if let imageData, let image = UIImage(data: imageData) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Image("cat_default")
                    .resizable()
                    .scaledToFit()
                    .padding(size * 0.08)
            }

            if isLoading {
                Circle().fill(Color.white.opacity(0.78))
                ProgressView()
                    .tint(AppColors.primaryDark)
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay {
            Circle()
                .stroke(AppColors.border, lineWidth: 1.5)
        }
        .shadow(color: AppColors.shadow.opacity(0.45), radius: 5, y: 3)
        .accessibilityLabel(imageData == nil ? "ここにゃんのプロフィール画像" : "プロフィール画像")
    }
}

struct FriendRemoteAvatarView: View {
    let store: FriendStore
    let avatarKey: String?
    var size: CGFloat = 64

    var body: some View {
        FriendAvatarView(
            imageData: store.avatarData(for: avatarKey),
            isLoading: store.isLoadingAvatar(path: avatarKey),
            size: size
        )
        .task(id: avatarKey) {
            await store.loadAvatar(path: avatarKey)
        }
    }
}

#if DEBUG
#Preview {
    FriendAvatarView(imageData: nil)
        .padding()
        .background(AppColors.background)
}
#endif
