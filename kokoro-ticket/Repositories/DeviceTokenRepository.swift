import Foundation

@MainActor
protocol DeviceTokenRepository {
    func register(token: String, environment: String, bundleID: String) async throws
    func deactivate(token: String, environment: String) async throws
}
