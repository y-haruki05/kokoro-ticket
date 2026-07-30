import Foundation
import Supabase

@MainActor
final class SupabaseProfileRepository: ProfileRepository {
    private static let avatarBucket = "profile-avatars"

    private let client: Supabase.SupabaseClient
    private let generator: FriendCodeGenerator
    private let maximumCodeGenerationAttempts: Int

    init(
        clientProvider: any SupabaseClientProviding,
        generator: FriendCodeGenerator = FriendCodeGenerator(),
        maximumCodeGenerationAttempts: Int = 10
    ) {
        client = clientProvider.client
        self.generator = generator
        self.maximumCodeGenerationAttempts = maximumCodeGenerationAttempts
    }

    func fetchCurrentProfile() async throws -> Profile? {
        let userID = try currentUserID()

        do {
            let records: [ProfileRecord] = try await client
                .from("profiles")
                .select()
                .eq("id", value: userID.uuidString)
                .limit(1)
                .execute()
                .value

            return records.first.map(Profile.init(record:))
        } catch {
            throw map(error, action: "プロフィールの取得")
        }
    }

    func createProfile(
        displayName: String,
        avatarKey: String?
    ) async throws -> Profile {
        let userID = try currentUserID()

        for _ in 0..<maximumCodeGenerationAttempts {
            let friendCode = generator.generate()

            guard try await isFriendCodeAvailable(friendCode) else {
                continue
            }

            do {
                let payload = ProfileInsert(
                    id: userID,
                    displayName: displayName,
                    friendCode: friendCode,
                    avatarKey: avatarKey
                )
                let record: ProfileRecord = try await client
                    .from("profiles")
                    .insert(payload)
                    .select()
                    .single()
                    .execute()
                    .value

                return Profile(record: record)
            } catch {
                if isUniqueConstraintViolation(error) {
                    continue
                }
                throw map(error, action: "プロフィールの作成")
            }
        }

        throw AppError.friendCodeGenerationFailed
    }

    func updateDisplayName(_ displayName: String) async throws -> Profile {
        let userID = try currentUserID()

        do {
            let payload = ProfileDisplayNameUpdate(
                displayName: displayName,
                updatedAt: .now
            )
            let record: ProfileRecord = try await client
                .from("profiles")
                .update(payload)
                .eq("id", value: userID.uuidString)
                .select()
                .single()
                .execute()
                .value

            return Profile(record: record)
        } catch {
            throw map(error, action: "表示名の更新")
        }
    }

    func fetchAvatarData(path: String) async throws -> Data {
        do {
            return try await client.storage
                .from(Self.avatarBucket)
                .download(path: path)
        } catch {
            throw mapAvatar(error, action: "プロフィール画像の取得")
        }
    }

    func updateAvatar(imageData: Data) async throws -> Profile {
        let userID = try currentUserID()
        let oldKey = try await fetchCurrentProfile()?.avatarKey
        let newKey = "\(userID.uuidString.lowercased())/avatar-\(UUID().uuidString.lowercased()).jpg"

        do {
            try await client.storage
                .from(Self.avatarBucket)
                .upload(
                    newKey,
                    data: imageData,
                    options: FileOptions(
                        cacheControl: "3600",
                        contentType: "image/jpeg",
                        upsert: false
                    )
                )
        } catch {
            throw mapAvatar(error, action: "プロフィール画像のアップロード")
        }

        do {
            let updated = try await updateAvatarKey(newKey, userID: userID)
            if let oldKey, oldKey != newKey {
                _ = try? await client.storage
                    .from(Self.avatarBucket)
                    .remove(paths: [oldKey])
            }
            return updated
        } catch {
            _ = try? await client.storage
                .from(Self.avatarBucket)
                .remove(paths: [newKey])
            throw error
        }
    }

    func removeAvatar() async throws -> Profile {
        let userID = try currentUserID()
        let oldKey = try await fetchCurrentProfile()?.avatarKey
        let updated = try await updateAvatarKey(nil, userID: userID)

        if let oldKey {
            do {
                try await client.storage
                    .from(Self.avatarBucket)
                    .remove(paths: [oldKey])
            } catch {
                // DB points to nil already. An orphaned object is safer than restoring a stale key.
                logAvatarCleanupFailure(error)
            }
        }
        return updated
    }

    func isFriendCodeAvailable(_ friendCode: String) async throws -> Bool {
        do {
            let isAvailable: Bool = try await client
                .rpc(
                    "is_friend_code_available",
                    params: ["candidate": friendCode]
                )
                .execute()
                .value

            return isAvailable
        } catch {
            throw map(error, action: "フレンドコードの確認")
        }
    }

    func reloadCurrentProfile() async throws -> Profile? {
        try await fetchCurrentProfile()
    }

    private func currentUserID() throws -> UUID {
        guard let userID = client.auth.currentUser?.id else {
            throw AppError.authenticatedUserUnavailable
        }
        return userID
    }

    private func updateAvatarKey(_ avatarKey: String?, userID: UUID) async throws -> Profile {
        do {
            let payload = ProfileAvatarUpdate(
                avatarKey: avatarKey,
                updatedAt: .now
            )
            let record: ProfileRecord = try await client
                .from("profiles")
                .update(payload)
                .eq("id", value: userID.uuidString)
                .select()
                .single()
                .execute()
                .value
            return Profile(record: record)
        } catch {
            throw mapAvatar(error, action: "プロフィール画像情報の更新")
        }
    }

    private func isUniqueConstraintViolation(_ error: Error) -> Bool {
        let description = String(reflecting: error)
        return description.contains("23505")
            || description.localizedCaseInsensitiveContains("unique")
    }

    private func map(_ error: Error, action: String) -> AppError {
        if let appError = error as? AppError {
            return appError
        }
        if let urlError = networkError(from: error) {
            return .network(description: urlError.localizedDescription)
        }
        if isUniqueConstraintViolation(error) {
            return .friendCodeDuplicated
        }
        return .profile(description: "\(action)に失敗しました: \(error.localizedDescription)")
    }

    private func mapAvatar(_ error: Error, action: String) -> AppError {
        if let appError = error as? AppError {
            return appError
        }
        logAvatarFailure(error, action: action)
        if networkError(from: error) != nil {
            return .network(description: error.localizedDescription)
        }
        if let storageError = error as? StorageError {
            let normalized = [
                storageError.error,
                storageError.message,
                storageError.statusCode
            ]
            .compactMap { $0 }
            .joined(separator: " ")
            .lowercased()

            if normalized.contains("bucket not found")
                || normalized.contains("no such bucket") {
                return .profileAvatarStorageUnavailable
            }
            if normalized.contains("unauthorized")
                || normalized.contains("row-level security")
                || normalized.contains("row level security")
                || normalized.contains("permission") {
                return .profileAvatarPermissionDenied
            }
            if normalized.contains("already exists")
                || normalized.contains("duplicate") {
                return .profileAvatarAlreadyExists
            }
            if normalized.contains("mime")
                || normalized.contains("content type") {
                return .profileAvatarInvalidMimeType
            }
        }
        if action.contains("取得") {
            return .profileAvatarLoadFailed
        }
        if action.contains("削除") {
            return .profileAvatarDeleteFailed
        }
        if action.contains("アップロード") {
            return .profileAvatarUploadFailed
        }
        return .profileAvatar(description: "\(action)に失敗しました")
    }

    private func logAvatarCleanupFailure(_ error: Error) {
        #if DEBUG
        print("[ProfileAvatar] 古い画像の削除に失敗しました: \(type(of: error))")
        #endif
    }

    private func logAvatarFailure(_ error: Error, action: String) {
        #if DEBUG
        if let storageError = error as? StorageError {
            print(
                """
                [ProfileAvatar] \(action)失敗 \
                type=StorageError \
                status=\(storageError.statusCode ?? "unknown") \
                code=\(storageError.error ?? "unknown") \
                message=\(sanitizedStorageLogMessage(storageError.message))
                """
            )
        } else {
            print(
                "[ProfileAvatar] \(action)失敗 type=\(String(describing: type(of: error)))"
            )
        }
        #endif
    }

    private func sanitizedStorageLogMessage(_ message: String) -> String {
        message
            .replacingOccurrences(
                of: #"[0-9a-fA-F-]{36}/[^\s\"']+"#,
                with: "<redacted-storage-path>",
                options: .regularExpression
            )
            .replacingOccurrences(
                of: #"https?://[^\s\"']+"#,
                with: "<redacted-url>",
                options: .regularExpression
            )
    }

    private func networkError(from error: Error) -> URLError? {
        if let urlError = error as? URLError {
            return urlError
        }
        return (error as NSError).userInfo[NSUnderlyingErrorKey] as? URLError
    }
}

private struct ProfileRecord: Decodable {
    let id: UUID
    let displayName: String
    let friendCode: String
    let avatarKey: String?
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case displayName = "display_name"
        case friendCode = "friend_code"
        case avatarKey = "avatar_key"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

private struct ProfileInsert: Encodable {
    let id: UUID
    let displayName: String
    let friendCode: String
    let avatarKey: String?

    enum CodingKeys: String, CodingKey {
        case id
        case displayName = "display_name"
        case friendCode = "friend_code"
        case avatarKey = "avatar_key"
    }
}

private struct ProfileDisplayNameUpdate: Encodable {
    let displayName: String
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case displayName = "display_name"
        case updatedAt = "updated_at"
    }
}

private struct ProfileAvatarUpdate: Encodable {
    let avatarKey: String?
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case avatarKey = "avatar_key"
        case updatedAt = "updated_at"
    }
}

private extension Profile {
    init(record: ProfileRecord) {
        self.init(
            id: record.id,
            displayName: record.displayName,
            friendCode: record.friendCode,
            avatarKey: record.avatarKey,
            createdAt: record.createdAt,
            updatedAt: record.updatedAt
        )
    }
}
