import SwiftUI

struct TutorialView: View {
    let mode: TutorialPresentationMode
    let onDismiss: () -> Void
    private let reduceMotionOverride: Bool?

    @State private var selection: TutorialPage
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    init(
        mode: TutorialPresentationMode,
        initialPage: TutorialPage = .welcome,
        reduceMotionOverride: Bool? = nil,
        onDismiss: @escaping () -> Void
    ) {
        self.mode = mode
        self.onDismiss = onDismiss
        self.reduceMotionOverride = reduceMotionOverride
        _selection = State(initialValue: initialPage)
    }

    var body: some View {
        VStack(spacing: 0) {
            topBar

            TabView(selection: $selection) {
                ForEach(TutorialPage.allCases) { page in
                    TutorialPageView(page: page)
                        .tag(page)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .accessibilityLabel("こころチケットの使い方")

            footer
        }
        .background(AppColors.background.ignoresSafeArea())
        .interactiveDismissDisabled(mode == .firstLaunch)
    }

    private var topBar: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 2) {
                    tutorialTitle
                    dismissButton
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            } else {
                HStack {
                    tutorialTitle
                    Spacer()
                    dismissButton
                }
            }
        }
        .padding(.horizontal, AppLayout.screenHorizontalPadding)
        .padding(.top, 8)
    }

    private var tutorialTitle: some View {
        Text("こころチケット")
            .font(.system(.headline, design: .rounded, weight: .bold))
            .foregroundStyle(AppColors.primaryDark)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var dismissButton: some View {
        Button(mode.dismissTitle, action: onDismiss)
            .font(.system(.subheadline, design: .rounded, weight: .bold))
            .foregroundStyle(AppColors.primaryDark)
            .frame(minWidth: AppLayout.minimumTapTarget, minHeight: AppLayout.minimumTapTarget)
            .accessibilityLabel(mode.dismissTitle)
    }

    private var footer: some View {
        VStack(spacing: 14) {
            TutorialPageIndicator(selection: selection)

            if dynamicTypeSize.isAccessibilitySize {
                VStack(spacing: 10) {
                    navigationButtons
                }
            } else {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 12) {
                        navigationButtons
                    }

                    VStack(spacing: 10) {
                        navigationButtons
                    }
                }
            }
        }
        .padding(.horizontal, AppLayout.screenHorizontalPadding)
        .padding(.top, 10)
        .padding(.bottom, 12)
        .background(AppColors.background)
    }

    @ViewBuilder
    private var navigationButtons: some View {
        if selection != .welcome {
            Button("戻る") {
                move(to: selection.rawValue - 1)
            }
            .buttonStyle(AppSecondaryButtonStyle())
            .accessibilityLabel("前のページへ戻る")
        }

        Button(selection == .memories ? mode.completionTitle : "次へ") {
            if selection == .memories {
                onDismiss()
            } else {
                move(to: selection.rawValue + 1)
            }
        }
        .buttonStyle(AppPrimaryButtonStyle())
        .accessibilityLabel(
            selection == .memories ? mode.completionTitle : "次のページへ進む"
        )
    }

    private func move(to rawValue: Int) {
        guard let page = TutorialPage(rawValue: rawValue) else { return }
        if reduceMotionOverride ?? systemReduceMotion {
            selection = page
        } else {
            withAnimation(.easeInOut(duration: 0.2)) {
                selection = page
            }
        }
    }
}

private struct TutorialPageView: View {
    let page: TutorialPage

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                illustration

                VStack(spacing: 12) {
                    Text(page.title)
                        .font(.system(.title2, design: .rounded, weight: .bold))
                        .foregroundStyle(AppColors.textPrimary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(page.message)
                        .font(.system(.body, design: .rounded, weight: .medium))
                        .foregroundStyle(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(5)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 4)
            }
            .frame(maxWidth: 560)
            .padding(.horizontal, AppLayout.screenHorizontalPadding)
            .padding(.top, 12)
            .padding(.bottom, 20)
            .frame(maxWidth: .infinity)
        }
        .scrollIndicators(.hidden)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("5ページ中\(page.pageNumber)ページ目、\(page.title)")
    }

    @ViewBuilder
    private var illustration: some View {
        switch page {
        case .welcome:
            Image("app_splash_logo")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 300, maxHeight: 240)
                .accessibilityLabel("こころチケットのロゴ")
        case .createTicket:
            TicketVisualView(
                title: "肩たたき券",
                message: "疲れた時に使ってね。心を込めて肩をたたきます！",
                illustration: TicketIllustration(id: "cat_ticket"),
                design: TicketDesign(backgroundColor: .white, borderStyle: .double)
            )
            .frame(maxWidth: 390)
            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        case .sendToFriend:
            TutorialIllustrationCard(
                image: "cat_welcome",
                systemImage: "paperplane.fill",
                label: "フレンドへチケットを贈る"
            )
        case .requestUsage:
            TutorialIllustrationCard(
                image: "cat_default",
                systemImage: "hand.tap.fill",
                label: "受け取ったチケットを使う"
            )
        case .memories:
            TutorialIllustrationCard(
                image: "cat_happy",
                systemImage: "photo.on.rectangle.angled",
                label: "完了したチケットを思い出に残す"
            )
        }
    }
}

private struct TutorialIllustrationCard: View {
    let image: String
    let systemImage: String
    let label: String

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(AppColors.cardBackground)
                .overlay {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(AppColors.border, lineWidth: 1.2)
                }
                .shadow(color: AppColors.shadow, radius: 10, y: 4)

            HStack(spacing: 22) {
                Image(image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 150, height: 150)
                    .accessibilityHidden(true)

                Image(systemName: systemImage)
                    .font(.system(size: 42, weight: .semibold))
                    .foregroundStyle(AppColors.primary)
                    .frame(width: 72, height: 72)
                    .background(AppColors.primarySoft)
                    .clipShape(Circle())
                    .accessibilityHidden(true)
            }
            .padding(22)
        }
        .frame(maxWidth: 390)
        .frame(height: 220)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
    }
}

private struct TutorialPageIndicator: View {
    let selection: TutorialPage

    var body: some View {
        HStack(spacing: 8) {
            ForEach(TutorialPage.allCases) { page in
                Capsule()
                    .fill(page == selection ? AppColors.primary : AppColors.cardBackground)
                    .frame(width: page == selection ? 22 : 9, height: 9)
                    .overlay {
                        Capsule().stroke(AppColors.primary, lineWidth: 1)
                    }
            }
        }
        .frame(minHeight: AppLayout.minimumTapTarget)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("5ページ中\(selection.pageNumber)ページ目")
    }
}

#Preview("Page 1") {
    TutorialView(mode: .firstLaunch, initialPage: .welcome, onDismiss: {})
}

#Preview("Page 2") {
    TutorialView(mode: .firstLaunch, initialPage: .createTicket, onDismiss: {})
}

#Preview("Page 3") {
    TutorialView(mode: .firstLaunch, initialPage: .sendToFriend, onDismiss: {})
}

#Preview("Page 4") {
    TutorialView(mode: .firstLaunch, initialPage: .requestUsage, onDismiss: {})
}

#Preview("Page 5 手動表示") {
    TutorialView(mode: .manual, initialPage: .memories, onDismiss: {})
}

#Preview("Dark Mode") {
    TutorialView(mode: .manual, onDismiss: {})
        .preferredColorScheme(.dark)
}

#Preview("iPhone SE", traits: .fixedLayout(width: 375, height: 667)) {
    TutorialView(mode: .firstLaunch, initialPage: .createTicket, onDismiss: {})
}

#Preview("Accessibility XXXL", traits: .sizeThatFitsLayout) {
    TutorialView(mode: .firstLaunch, initialPage: .memories, onDismiss: {})
        .environment(\.dynamicTypeSize, .accessibility3)
        .frame(width: 375, height: 812)
}

#Preview("Reduce Motion") {
    TutorialView(
        mode: .firstLaunch,
        initialPage: .requestUsage,
        reduceMotionOverride: true,
        onDismiss: {}
    )
}
