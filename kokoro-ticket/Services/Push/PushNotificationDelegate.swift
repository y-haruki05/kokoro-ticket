import Foundation
import UIKit
import UserNotifications

@MainActor
final class PushNotificationDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    static let shared = PushNotificationDelegate()
    private static var launchPayload: [AnyHashable: Any]?
    var onToken: ((Data) -> Void)?
    var onRegistrationError: ((Error) -> Void)?
    var onReceive: (([AnyHashable: Any], Bool) -> Void)?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        if let payload = launchOptions?[.remoteNotification] as? [AnyHashable: Any] {
            if let handler = Self.shared.onReceive {
                handler(payload, true)
            } else {
                Self.launchPayload = payload
            }
        }
        return true
    }

    func consumeLaunchPayload() {
        guard let payload = Self.launchPayload else { return }
        Self.launchPayload = nil
        onReceive?(payload, true)
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        Self.shared.onToken?(deviceToken)
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        Self.shared.onRegistrationError?(error)
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        await MainActor.run {
            Self.shared.onReceive?(notification.request.content.userInfo, false)
        }
        return [.banner, .sound]
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        await MainActor.run {
            Self.shared.onReceive?(response.notification.request.content.userInfo, true)
        }
    }
}
