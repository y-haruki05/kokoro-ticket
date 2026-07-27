import Foundation
import Supabase

@MainActor
final class SupabaseDeviceTokenRepository: DeviceTokenRepository {
    private let client: Supabase.SupabaseClient

    init(clientProvider: any SupabaseClientProviding) {
        client = clientProvider.client
    }

    func register(token: String, environment: String, bundleID: String) async throws {
        do {
            let _: UUID = try await client.rpc(
                "register_device_token",
                params: [
                    "target_token": token,
                    "target_environment": environment,
                    "target_bundle_id": bundleID
                ]
            ).execute().value
        } catch {
            throw AppError.deviceTokenSaveFailed
        }
    }

    func deactivate(token: String, environment: String) async throws {
        do {
            let _: Bool = try await client.rpc(
                "deactivate_device_token",
                params: [
                    "target_token": token,
                    "target_environment": environment
                ]
            ).execute().value
        } catch {
            throw AppError.deviceTokenDeactivationFailed
        }
    }
}
