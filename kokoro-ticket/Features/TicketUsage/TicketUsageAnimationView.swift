import SwiftUI

struct TicketUsageAnimationView: View {
    let ticket: TicketListItem
    let onAnimationCompleted: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var hasStarted = false
    @State private var hasCompleted = false
    @State private var isTorn = false
    @State private var isLeftReleased = false
    @State private var isRightReleased = false
    @State private var stretchX: CGFloat = 1
    @State private var stretchY: CGFloat = 1
    @State private var ticketOpacity = 1.0
    @State private var showsUsedMessage = false
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
                    if showsUsedMessage {
                        Text("チケットを使いました！")
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

        if reduceMotion {
            await playReducedMotionSequence()
        } else {
            await playTearSequence()
        }
    }

    @MainActor
    private func playTearSequence() async {
        await wait(500)

        withAnimation(.easeInOut(duration: 0.30)) {
            stretchX = 1.065
            stretchY = 0.965
        }

        await wait(320)

        isTorn = true
        stretchX = 1
        stretchY = 1

        await wait(70)

        withAnimation(.spring(response: 0.62, dampingFraction: 0.72)) {
            isLeftReleased = true
        }

        await wait(100)

        withAnimation(.spring(response: 0.66, dampingFraction: 0.74)) {
            isRightReleased = true
        }

        await wait(360)

        withAnimation(.spring(response: 0.42, dampingFraction: 0.82)) {
            showsUsedMessage = true
        }

        await wait(220)

        withAnimation(.spring(response: 0.50, dampingFraction: 0.70)) {
            showsThanks = true
        }

        await wait(820)
        completeOnce()
    }

    @MainActor
    private func playReducedMotionSequence() async {
        await wait(400)

        withAnimation(.easeInOut(duration: 0.25)) {
            ticketOpacity = 0.45
            showsUsedMessage = true
            showsThanks = true
        }

        await wait(1_000)
        completeOnce()
    }

    @MainActor
    private func completeOnce() {
        guard !hasCompleted else { return }
        hasCompleted = true
        onAnimationCompleted()
    }

    private func wait(_ milliseconds: UInt64) async {
        try? await Task.sleep(nanoseconds: milliseconds * 1_000_000)
    }
}

#Preview {
    TicketUsageAnimationView(
        ticket: MockTicketListItems.items[0],
        onAnimationCompleted: {}
    )
}
