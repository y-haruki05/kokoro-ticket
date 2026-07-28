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
            rootView
        }
        .modelContainer(modelContainer)
    }

    @ViewBuilder
    private var rootView: some View {
        #if DEBUG
        if CommandLine.arguments.contains("-home-preview") {
            HomeVerificationRootView()
        } else if CommandLine.arguments.contains("-memories-preview") {
            MemoriesVerificationRootView()
        } else if CommandLine.arguments.contains("-ticket-list-preview") {
            TicketListVerificationRootView()
        } else if CommandLine.arguments.contains("-profile-preview") {
            ProfileVerificationRootView()
        } else if CommandLine.arguments.contains("-auth-preview") {
            AuthenticationVerificationRootView()
        } else {
            authenticationRoot
        }
        #else
        authenticationRoot
        #endif
    }

    private var authenticationRoot: some View {
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
}
