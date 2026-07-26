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
            !projectURLString.localizedCaseInsensitiveContains("placeholder"),
            !projectURLString.contains("YOUR_PROJECT_REF")
        else {
            throw AppError.invalidConfiguration(
                key: "SUPABASE_URL",
                reason: "Secrets.local.xcconfigに実際のProject URLを設定してください"
            )
        }

        guard
            !anonKey.localizedCaseInsensitiveContains("placeholder"),
            !anonKey.contains("YOUR_SUPABASE_ANON_KEY")
        else {
            throw AppError.invalidConfiguration(
                key: "SUPABASE_ANON_KEY",
                reason: "Secrets.local.xcconfigに実際のAnon Keyを設定してください"
            )
        }

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
