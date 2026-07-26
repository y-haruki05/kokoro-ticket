import Foundation
import Supabase

@MainActor
final class SupabaseProfileRepository: ProfileRepository {
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
