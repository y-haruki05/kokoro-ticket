import UIKit

@MainActor
protocol ClipboardWriting {
    func copy(_ text: String)
}

@MainActor
struct SystemClipboardService: ClipboardWriting {
    func copy(_ text: String) {
        UIPasteboard.general.string = text
    }
}

@MainActor
struct PreviewClipboardService: ClipboardWriting {
    func copy(_ text: String) {}
}
