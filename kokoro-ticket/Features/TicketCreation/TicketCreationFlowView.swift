import SwiftUI

/// 内容・イラスト・デザイン・完成確認の作成ステップを管理するView
struct TicketCreationFlowView: View {
    var onSave: (TicketCreationDraftSnapshot) -> Bool = { _ in true }
    let onClose: () -> Void

    /// 作成ステップ間を進むNavigationStackの経路
    @State private var path: [TicketCreationRoute] = []
    /// 全ステップで共有し、プレビューへ即時反映する保存前データ
    @State private var draft = TicketCreationDraft()

    var body: some View {
        NavigationStack(path: $path) {
            TicketContentInputView(
                draft: draft,
                onBack: onClose,
                onNext: {
                    path.append(.illustration)
                }
            )
            .navigationDestination(for: TicketCreationRoute.self) { route in
                switch route {
                case .illustration:
                    TicketIllustrationSelectionView(
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
    case illustration
    case design
    case confirmation
}

#Preview("通常") {
    TicketCreationFlowView(onClose: {})
}
