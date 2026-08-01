import SwiftUI

/// 完了成功後だけ半券破り演出を表示し、終了後に思い出へ遷移する画面
struct TicketUsageAnimationView: View {
    let ticket: TicketListItem
    let onAnimationCompleted: () -> Void
    var reduceMotionOverride: Bool? = nil

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var hasStarted = false
    @State private var hasCompleted = false
    @State private var isTorn = false
    @State private var isLeftReleased = false
    @State private var isRightReleased = false
    @State private var stretchX: CGFloat = 1
    @State private var stretchY: CGFloat = 1
    @State private var ticketOpacity = 1.0
    @State private var showsCompletionMessage = false
    @State private var showsThanks = false

    var body: some View {
        ZStack {
            background

            VStack(spacing: 22) {
                Spacer()

                TornTicketView(
                    ticket: ticket,
                    isTorn: isTorn,
                    isLeftReleased: isLeftReleased,
                    isRightReleased: isRightReleased,
                    stretchX: stretchX,
                    stretchY: stretchY,
                    opacity: ticketOpacity
                )
                .frame(maxWidth: 340)
                .frame(height: 230)
                .padding(.horizontal, 24)

                VStack(spacing: 9) {
                    if showsCompletionMessage {
                        Text("チケットが完了しました！")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(AppColors.primaryDark)
                            .transition(.opacity.combined(with: .scale(scale: 0.96)))
                    }

                    if showsThanks {
                        Text("ありがとう！")
                            .font(.system(size: 38, weight: .bold, design: .rounded))
                            .foregroundStyle(AppColors.primary)
                            .transition(.opacity.combined(with: .scale(scale: 0.82)))
                    }
                }
                .frame(height: 88)

                Spacer()
            }
            .padding(.vertical, 30)
        }
        .ignoresSafeArea()
        .interactiveDismissDisabled(true)
        .accessibilityElement(children: .contain)
        .task {
            await startAnimationIfNeeded()
        }
    }

    private var background: some View {
        ZStack {
            LinearGradient(
                colors: [
                    AppColors.primarySoft,
                    AppColors.pastelBlue,
                    AppColors.cardBackground
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(AppColors.cardBackground.opacity(0.36))
                .frame(width: 360, height: 360)
                .blur(radius: 2)

            Circle()
                .stroke(AppColors.primary.opacity(0.10), lineWidth: 34)
                .frame(width: 520, height: 520)
        }
    }

    @MainActor
    private func startAnimationIfNeeded() async {
        guard !hasStarted else { return }
        hasStarted = true

        if reduceMotionOverride ?? reduceMotion {
            await playReducedMotionSequence()
        } else {
            await playTearSequence()
        }
    }

    @MainActor
    private func playTearSequence() async {
        guard await wait(500) else { return }

        withAnimation(.easeInOut(duration: 0.30)) {
            stretchX = 1.065
            stretchY = 0.965
        }

        guard await wait(320) else { return }

        isTorn = true
        stretchX = 1
        stretchY = 1

        guard await wait(70) else { return }

        withAnimation(.spring(response: 0.62, dampingFraction: 0.72)) {
            isLeftReleased = true
        }

        guard await wait(100) else { return }

        withAnimation(.spring(response: 0.66, dampingFraction: 0.74)) {
            isRightReleased = true
        }

        guard await wait(360) else { return }

        withAnimation(.spring(response: 0.42, dampingFraction: 0.82)) {
            showsCompletionMessage = true
        }

        guard await wait(220) else { return }

        withAnimation(.spring(response: 0.50, dampingFraction: 0.70)) {
            showsThanks = true
        }

        guard await wait(820) else { return }
        completeOnce()
    }

    @MainActor
    private func playReducedMotionSequence() async {
        guard await wait(400) else { return }

        withAnimation(.easeInOut(duration: 0.25)) {
            ticketOpacity = 0.45
            showsCompletionMessage = true
            showsThanks = true
        }

        guard await wait(1_000) else { return }
        completeOnce()
    }

    @MainActor
    private func completeOnce() {
        guard !hasCompleted else { return }
        hasCompleted = true
        onAnimationCompleted()
    }

    private func wait(_ milliseconds: UInt64) async -> Bool {
        do {
            try await Task.sleep(nanoseconds: milliseconds * 1_000_000)
            return !Task.isCancelled
        } catch {
            return false
        }
    }
}

#Preview {
    TicketUsageAnimationView(
        ticket: MockTicketListItems.items[0],
        onAnimationCompleted: {}
    )
}

#Preview("半券破り演出前") {
    TornTicketView(
        ticket: MockTicketListItems.items[3],
        isTorn: false,
        isLeftReleased: false,
        isRightReleased: false,
        stretchX: 1,
        stretchY: 1,
        opacity: 1
    )
    .padding()
    .background(AppColors.primarySoft)
}

#Preview("Reduce Motion") {
    TicketUsageAnimationView(
        ticket: MockTicketListItems.items[4],
        onAnimationCompleted: {},
        reduceMotionOverride: true
    )
}
