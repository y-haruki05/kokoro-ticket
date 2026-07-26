import Foundation

enum EmailAddressValidator {
    static func normalized(_ email: String) throws -> String {
        let normalized = email
            .precomposedStringWithCompatibilityMapping
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !normalized.isEmpty else {
            throw AppError.emailRequired
        }

        guard
            !normalized.unicodeScalars.contains(where: {
                CharacterSet.whitespacesAndNewlines.contains($0)
                    || CharacterSet.controlCharacters.contains($0)
                    || CharacterSet.illegalCharacters.contains($0)
                    || $0.properties.generalCategory == .format
            }),
            normalized.filter({ $0 == "@" }).count == 1
        else {
            throw AppError.invalidEmail
        }

        let components = normalized.split(
            separator: "@",
            maxSplits: 1,
            omittingEmptySubsequences: false
        )
        guard
            components.count == 2,
            !components[0].isEmpty,
            let domain = components.last,
            domain.contains("."),
            !domain.hasPrefix("."),
            !domain.hasSuffix(".")
        else {
            throw AppError.invalidEmail
        }

        return normalized
    }
}
