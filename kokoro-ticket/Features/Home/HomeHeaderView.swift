import SwiftUI

struct HomeHeaderView: View {
    var unreadCount = 0
    var onNotificationTap: () -> Void = {}

    var body: some View {
        ZStack {
            Text("こころチケット")
                .font(AppTypography.screenTitle)
                .foregroundStyle(AppColors.primary)

            HStack {
                Spacer()

                Button(action: onNotificationTap) {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "bell")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(AppColors.primaryDark)
                            .frame(width: 44, height: 44)
                            .background(AppColors.primarySoft)
                            .clipShape(Circle())

                        if unreadCount > 0 {
                            Text(unreadCount > 99 ? "99+" : "\(unreadCount)")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 5)
                                .frame(minWidth: 19, minHeight: 19)
                                .background(AppColors.error)
                                .clipShape(Capsule())
                                .offset(x: 4, y: -3)
                        }
                    }
                }
                .accessibilityLabel("通知、未読\(unreadCount)件")
                .accessibilityHint("通知一覧を開きます")
            }
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    HomeHeaderView(unreadCount: 120)
        .padding()
}
