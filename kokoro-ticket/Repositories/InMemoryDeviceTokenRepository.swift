import Foundation

@MainActor
final class InMemoryDeviceTokenRepository: DeviceTokenRepository {
    private(set) var activeTokens = Set<String>()
    var error: AppError?

    func register(token: String, environment: String, bundleID: String) async throws {
        if let error { throw error }
        activeTokens.insert("\(environment):\(token)")
    }

    func deactivate(token: String, environment: String) async throws {
        if let error { throw error }
        activeTokens.remove("\(environment):\(token)")
    }
}
