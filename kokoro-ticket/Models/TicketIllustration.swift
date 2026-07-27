import Foundation

struct TicketIllustration: Identifiable, Hashable {
    let id: String

    var assetName: String {
        let supportedAssets = [
            "cat_default",
            "cat_happy",
            "cat_sad",
            "cat_ticket",
            "cat_welcome"
        ]

        return supportedAssets.contains(id) ? id : "cat_default"
    }
}
