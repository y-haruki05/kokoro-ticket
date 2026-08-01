import Foundation
import OSLog
import SwiftData

/// ローカルチケットを保存するSwiftDataコンテナを安全に生成・移行する
enum SwiftDataContainerFactory {
    private static let currentSchemaVersion = 3
    private static let schemaVersionKey = "SwiftDataTicketSchemaVersion"
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.haruki.kokoro-ticket",
        category: "SwiftData"
    )

    static func makeContainer() throws -> ModelContainer {
        let storeURL = try persistentStoreURL()

        do {
            let container = try createContainer(storeURL: storeURL)
            recordCurrentSchemaVersion()
            return container
        } catch {
            log(error, stage: "initial-load", storeURL: storeURL)

#if DEBUG
            guard shouldResetLegacyStore(after: error, storeURL: storeURL) else {
                throw error
            }

            logger.warning(
                "DEBUG: 旧SwiftDataストアを削除して1回だけ再作成します。store=\(storeURL.path, privacy: .public)"
            )

            do {
                try removeStoreFiles(at: storeURL)
            } catch {
                log(error, stage: "legacy-store-removal", storeURL: storeURL)
                throw error
            }

            do {
                let container = try createContainer(storeURL: storeURL)
                recordCurrentSchemaVersion()
                logger.info("DEBUG: SwiftDataストアの再作成に成功しました。")
                return container
            } catch {
                log(error, stage: "retry-after-reset", storeURL: storeURL)
                throw error
            }
#else
            throw error
#endif
        }
    }

    static func logFatalInitializationError(_ error: Error) {
        let storeURL = try? persistentStoreURL()
        log(error, stage: "fatal", storeURL: storeURL)
    }

    private static func createContainer(storeURL: URL) throws -> ModelContainer {
        let schema = Schema([Ticket.self])
        let configuration = ModelConfiguration(
            schema: schema,
            url: storeURL
        )
        return try ModelContainer(
            for: schema,
            configurations: [configuration]
        )
    }

    private static func persistentStoreURL() throws -> URL {
        guard let applicationSupportURL = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first else {
            throw CocoaError(.fileNoSuchFile)
        }

        try FileManager.default.createDirectory(
            at: applicationSupportURL,
            withIntermediateDirectories: true
        )

        return applicationSupportURL.appendingPathComponent("default.store")
    }

#if DEBUG
    private static func shouldResetLegacyStore(
        after error: Error,
        storeURL: URL
    ) -> Bool {
        let storedSchemaVersion = UserDefaults.standard.integer(
            forKey: schemaVersionKey
        )
        let isOlderSchema = storedSchemaVersion < currentSchemaVersion
        let storeExists = FileManager.default.fileExists(atPath: storeURL.path)
        let isContainerLoadFailure = String(reflecting: error)
            .contains("loadIssueModelContainer")

        return isOlderSchema && storeExists && isContainerLoadFailure
    }

    private static func removeStoreFiles(at storeURL: URL) throws {
        let fileManager = FileManager.default
        let relatedURLs = [
            URL(fileURLWithPath: storeURL.path + "-wal"),
            URL(fileURLWithPath: storeURL.path + "-shm"),
            URL(fileURLWithPath: storeURL.path + "-journal"),
            storeURL
        ]

        for url in relatedURLs where fileManager.fileExists(atPath: url.path) {
            try fileManager.removeItem(at: url)
            logger.info("DEBUG: 削除しました: \(url.lastPathComponent, privacy: .public)")
        }
    }
#endif

    private static func recordCurrentSchemaVersion() {
        UserDefaults.standard.set(
            currentSchemaVersion,
            forKey: schemaVersionKey
        )
    }

    private static func log(
        _ error: Error,
        stage: String,
        storeURL: URL?
    ) {
        let nsError = error as NSError
        let storePath = storeURL?.path ?? "取得失敗"

        logger.error(
            """
            SwiftData初期化エラー stage=\(stage, privacy: .public)
            store=\(storePath, privacy: .public)
            error=\(String(reflecting: error), privacy: .public)
            domain=\(nsError.domain, privacy: .public)
            code=\(nsError.code)
            userInfo=\(String(describing: nsError.userInfo), privacy: .public)
            """
        )

        if let underlyingError = nsError.userInfo[NSUnderlyingErrorKey] as? Error {
            let underlyingNSError = underlyingError as NSError
            logger.error(
                """
                SwiftData underlyingError=\(String(reflecting: underlyingError), privacy: .public)
                domain=\(underlyingNSError.domain, privacy: .public)
                code=\(underlyingNSError.code)
                userInfo=\(String(describing: underlyingNSError.userInfo), privacy: .public)
                """
            )
        }
    }
}
