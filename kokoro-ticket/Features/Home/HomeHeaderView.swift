import SwiftUI

struct HomeHeaderView: View {
    var onNotificationTap: () -> Void = {}

    var body: some View {
        ZStack {
            Text("こころチケット")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(AppColors.primary)

            HStack {
                Spacer()

                Button(action: onNotificationTap) {
                    Image(systemName: "bell")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(AppColors.primaryDark)
                        .frame(width: 44, height: 44)
                        .background(AppColors.primarySoft)
                        .clipShape(Circle())
                }
                .accessibilityLabel("通知")
            }
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    HomeHeaderView()
        .padding()
}
