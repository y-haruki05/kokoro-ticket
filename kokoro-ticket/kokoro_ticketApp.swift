//
//  kokoro_ticketApp.swift
//  kokoro-ticket
//
//  Created by 山本悠生 on 2026/07/25.
//

import SwiftUI
import SwiftData

@main
struct kokoro_ticketApp: App {
    @UIApplicationDelegateAdaptor(PushNotificationDelegate.self) private var appDelegate
    private let modelContainer: ModelContainer
    private let supabaseClientProvider: any SupabaseClientProviding

    init() {
        supabaseClientProvider = SupabaseClientProvider.shared

        do {
            modelContainer = try SwiftDataContainerFactory.makeContainer()
        } catch {
            SwiftDataContainerFactory.logFatalInitializationError(error)
            fatalError(
                """
                SwiftDataの初期化に失敗しました。
                詳細はSwiftDataカテゴリのログを確認してください。
                \(String(reflecting: error))
                """
            )
        }
    }

    var body: some Scene {
        WindowGroup {
            AuthenticationRootView(
                authRepository: SupabaseAuthRepository(
                    clientProvider: supabaseClientProvider
                ),
                profileRepository: SupabaseProfileRepository(
                    clientProvider: supabaseClientProvider
                ),
                friendRepository: SupabaseFriendRepository(
                    clientProvider: supabaseClientProvider
                ),
                notificationRepository: SupabaseNotificationRepository(
                    clientProvider: supabaseClientProvider
                ),
                deviceTokenRepository: SupabaseDeviceTokenRepository(
                    clientProvider: supabaseClientProvider
                ),
                ticketRepository: SupabaseTicketRepository(
                    localRepository: SwiftDataTicketRepository(
                        modelContext: modelContainer.mainContext
                    ),
                    clientProvider: supabaseClientProvider
                ),
                realtimeService: SupabaseRealtimeService(
                    clientProvider: supabaseClientProvider
                )
            )
        }
        .modelContainer(modelContainer)
    }
}
