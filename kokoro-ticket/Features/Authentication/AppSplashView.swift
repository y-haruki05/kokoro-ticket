import SwiftUI

struct AppSplashView: View {
    var body: some View {
        GeometryReader { proxy in
            Image("app_splash_logo")
                .resizable()
                .scaledToFit()
                .frame(width: min(proxy.size.width * 0.8, 420))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .accessibilityLabel("こころチケット。きもちを、チケットに。")
        }
        .background(Color.white.ignoresSafeArea())
    }
}

#Preview("スプラッシュ") {
    AppSplashView()
}

#Preview("Dark Mode") {
    AppSplashView()
        .preferredColorScheme(.dark)
}
