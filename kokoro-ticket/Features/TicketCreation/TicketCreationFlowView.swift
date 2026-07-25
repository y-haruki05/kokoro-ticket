import SwiftUI

struct TicketCreationFlowView: View {
    var onSave: (TicketCreationDraftSnapshot) -> Void = { _ in }
    let onClose: () -> Void

    @State private var path: [TicketCreationRoute] = []
    @State private var draft = TicketCreationDraft()

    var body: some View {
        NavigationStack(path: $path) {
            TicketIllustrationSelectionView(
                draft: draft,
                onBack: onClose,
                onNext: {
                    path.append(.contentInput)
                }
            )
            .navigationDestination(for: TicketCreationRoute.self) { route in
                switch route {
                case .contentInput:
                    TicketContentInputView(
                        draft: draft,
                        onBack: navigateBack,
                        onNext: {
                            path.append(.design)
                        }
                    )
                case .design:
                    TicketDesignSelectionView(
                        draft: draft,
                        onBack: navigateBack,
                        onNext: {
                            path.append(.confirmation)
                        }
                    )
                case .confirmation:
                    TicketConfirmationView(
                        draft: draft,
                        onBack: navigateBack,
                        onSave: onSave,
                        onSaveCompleted: finishCreation
                    )
                }
            }
        }
    }

    private func navigateBack() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    private func finishCreation() {
        draft.reset()
        path.removeAll()
        onClose()
    }
}

private enum TicketCreationRoute: Hashable {
    case contentInput
    case design
    case confirmation
}

#Preview {
    TicketCreationFlowView(onClose: {})
}
