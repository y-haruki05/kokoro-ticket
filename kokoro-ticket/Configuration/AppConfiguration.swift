import Foundation

struct SupabaseConfiguration: Sendable {
    let projectURL: URL
    let anonKey: String
}

struct AppConfiguration: Sendable {
    let supabase: SupabaseConfiguration

    static func load(from bundle: Bundle = .main) throws -> AppConfiguration {
        let projectURLString = try requiredValue(
            forKey: "SUPABASE_URL",
            from: bundle
        )
        let anonKey = try requiredValue(
            forKey: "SUPABASE_ANON_KEY",
            from: bundle
        )

        guard
            let projectURL = URL(string: projectURLString),
            projectURL.scheme == "https",
            projectURL.host != nil
        else {
            throw AppError.invalidConfiguration(
                key: "SUPABASE_URL",
                reason: "HTTPS形式のURLを設定してください"
            )
        }

        return AppConfiguration(
            supabase: SupabaseConfiguration(
                projectURL: projectURL,
                anonKey: anonKey
            )
        )
    }

    private static func requiredValue(
        forKey key: String,
        from bundle: Bundle
    ) throws -> String {
        guard
            let value = bundle.object(forInfoDictionaryKey: key) as? String,
            !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            throw AppError.missingConfiguration(key: key)
        }
        return value
    }
}
