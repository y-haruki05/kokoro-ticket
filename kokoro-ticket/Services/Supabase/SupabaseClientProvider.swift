import Foundation
import Supabase

protocol SupabaseClientProviding: Sendable {
    var client: Supabase.SupabaseClient { get }
}

final class SupabaseClientProvider: SupabaseClientProviding, @unchecked Sendable {
    static let shared: SupabaseClientProvider = {
        do {
            return try SupabaseClientProvider(
                configuration: AppConfiguration.load().supabase
            )
        } catch {
            fatalError(
                "Supabaseクライアントの初期化に失敗しました: \(error.localizedDescription)"
            )
        }
    }()

    let client: Supabase.SupabaseClient

    init(configuration: SupabaseConfiguration) throws {
        guard !configuration.anonKey.isEmpty else {
            throw AppError.missingConfiguration(key: "SUPABASE_ANON_KEY")
        }

        client = Supabase.SupabaseClient(
            supabaseURL: configuration.projectURL,
            supabaseKey: configuration.anonKey
        )
    }
}
