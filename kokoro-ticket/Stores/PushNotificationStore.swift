import Foundation
import Observation
import UIKit
import UserNotifications

@MainActor
@Observable
final class PushNotificationStore {
    private(set) var authorizationStatus: PushAuthorizationStatus = .notDetermined
    private(set) var deviceTokenRegistrationState: DeviceTokenRegistrationState = .idle
    private(set) var isRequestingAuthorization = false
    private(set) var isRegisteringToken = false
    private(set) var error: AppError?
    private(set) var lastReceivedNotification: PushNotificationPayload?
    private(set) var pendingDeepLink: PushNotificationPayload?
    private(set) var deviceToken: String?

    @ObservationIgnored private let repository: any DeviceTokenRepository
    @ObservationIgnored private let environment: String

    init(repository: any DeviceTokenRepository, environment: String) {
        self.repository = repository
        self.environment = environment
        configureDelegate()
    }

    func refreshAuthorizationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        authorizationStatus = switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral: .authorized
        case .denied: .denied
        default: .notDetermined
        }
        if authorizationStatus == .authorized {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }

    func requestAuthorization() async {
        guard authorizationStatus == .notDetermined, !isRequestingAuthorization else { return }
        isRequestingAuthorization = true
        defer { isRequestingAuthorization = false }
        do {
            let allowed = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound])
            authorizationStatus = allowed ? .authorized : .denied
            if allowed { UIApplication.shared.registerForRemoteNotifications() }
        } catch {
            self.error = .pushAuthorizationFailed
        }
    }

    func deactivateForLogout() async {
        guard let deviceToken else { return }
        try? await repository.deactivate(token: deviceToken, environment: environment)
    }

    func consumePendingDeepLink() -> PushNotificationPayload? {
        defer { pendingDeepLink = nil }
        return pendingDeepLink
    }

    func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    private func configureDelegate() {
        let delegate = PushNotificationDelegate.shared
        delegate.onToken = { [weak self] data in
            Task { await self?.register(data) }
        }
        delegate.onRegistrationError = { [weak self] _ in
            self?.error = .apnsRegistrationFailed
            self?.deviceTokenRegistrationState = .failed
        }
        delegate.onReceive = { [weak self] userInfo, wasTapped in
            guard let self else { return }
            do {
                let payload = try PushNotificationPayload(userInfo: userInfo)
                lastReceivedNotification = payload
                if wasTapped { pendingDeepLink = payload }
            } catch {
                self.error = .pushPayloadInvalid
            }
        }
        delegate.consumeLaunchPayload()
    }

    private func register(_ data: Data) async {
        guard !isRegisteringToken else { return }
        let token = data.map { String(format: "%02x", $0) }.joined()
        deviceToken = token
        isRegisteringToken = true
        deviceTokenRegistrationState = .registering
        defer { isRegisteringToken = false }
        do {
            try await repository.register(
                token: token,
                environment: environment,
                bundleID: Bundle.main.bundleIdentifier ?? ""
            )
            deviceTokenRegistrationState = .registered
        } catch {
            self.error = .deviceTokenSaveFailed
            deviceTokenRegistrationState = .failed
        }
    }
}
