#if DEBUG
import SwiftUI

struct TutorialVerificationRootView: View {
    var body: some View {
        TutorialView(
            mode: CommandLine.arguments.contains("-tutorial-manual")
                ? .manual
                : .firstLaunch,
            initialPage: initialPage,
            onDismiss: {}
        )
    }

    private var initialPage: TutorialPage {
        guard
            let argument = CommandLine.arguments.first(where: { $0.hasPrefix("-tutorial-page=") }),
            let value = Int(argument.replacingOccurrences(of: "-tutorial-page=", with: "")),
            let page = TutorialPage(rawValue: value - 1)
        else { return .welcome }
        return page
    }
}
#endif
