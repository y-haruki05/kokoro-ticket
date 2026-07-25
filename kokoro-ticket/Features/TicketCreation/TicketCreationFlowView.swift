import SwiftUI

struct TicketCreationFlowView: View {
    let onClose: () -> Void

    @State private var path: [TicketCreationRoute] = []
    @State private var selectedIllustration: TicketIllustration?
    @State private var ticketContent = TicketContent()

    var body: some View {
        NavigationStack(path: $path) {
            TicketIllustrationSelectionView(
                onBack: onClose,
                onNext: { illustration in
                    selectedIllustration = illustration
                    path.append(.contentInput)
                }
            )
            .navigationDestination(for: TicketCreationRoute.self) { route in
                switch route {
                case .contentInput:
                    TicketContentInputView(
                        initialContent: ticketContent,
                        onBack: navigateBack,
                        onNext: { content in
                            ticketContent = content
                            path.append(.design)
                        }
                    )
                case .design:
                    TicketDesignPlaceholderView(onBack: navigateBack)
                }
            }
        }
    }

    private func navigateBack() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }
}

private enum TicketCreationRoute: Hashable {
    case contentInput
    case design
}

private struct TicketDesignPlaceholderView: View {
    let onBack: () -> Void

    var body: some View {
        VStack(spacing: 28) {
            TicketCreationHeaderView(onBack: onBack)

            TicketCreationStepIndicatorView(activeStep: 3)

            Spacer()

            Text("デザイン画面は今後実装予定です")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(AppColors.textSecondary)

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .background(AppColors.background.ignoresSafeArea())
        .navigationBarHidden(true)
    }
}

#Preview {
    TicketCreationFlowView(onClose: {})
}
