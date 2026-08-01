import PhotosUI
import SwiftUI
import UIKit

// プロフィール表示・画像変更・設定項目・ログアウト導線をまとめるマイページ
@MainActor
struct ProfileView: View {
    let store: ProfileStore
    let friendStore: FriendStore
    let email: String?
    let isAuthLoading: Bool
    let onLogout: () -> Void
    @Binding private var deepLink: AppDeepLink?

    private let clipboard: any ClipboardWriting
    private let showsTutorialInitially: Bool

    @State private var selectedPhoto: PhotosPickerItem?
    @State private var isShowingNameEditor = false
    @State private var isShowingLogoutConfirmation = false
    @State private var isShowingAvatarDeleteConfirmation = false
    @State private var showsCopyMessage = false
    @State private var showsAvatarMessage = false
    @State private var isShowingTutorial = false
    @State private var didApplyInitialTutorialPresentation = false

    init(
        store: ProfileStore,
        friendStore: FriendStore,
        email: String?,
        isAuthLoading: Bool,
        clipboard: any ClipboardWriting,
        deepLink: Binding<AppDeepLink?> = .constant(nil),
        showsAvatarDeleteConfirmationInitially: Bool = false,
        showsTutorialInitially: Bool = false,
        onLogout: @escaping () -> Void
    ) {
        self.store = store
        self.friendStore = friendStore
        self.email = email
        self.isAuthLoading = isAuthLoading
        self.clipboard = clipboard
        _deepLink = deepLink
        _isShowingAvatarDeleteConfirmation = State(
            initialValue: showsAvatarDeleteConfirmationInitially
        )
        _isShowingTutorial = State(initialValue: false)
        self.showsTutorialInitially = showsTutorialInitially
        self.onLogout = onLogout
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                Group {
                    if store.isLoading && store.profile == nil {
                        loadingContent
                    } else if let profile = store.profile {
                        profileContent(profile)
                    } else {
                        unavailableContent
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 112)
            }
            .refreshable {
                await store.reloadProfile()
            }
            .background(AppColors.background)
            .navigationTitle("マイページ")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $isShowingNameEditor) {
                ProfileDisplayNameEditView(store: store)
                    .presentationDetents([.medium, .large])
            }
            .fullScreenCover(isPresented: $isShowingTutorial) {
                TutorialView(mode: .manual) {
                    isShowingTutorial = false
                }
            }
            .task {
                guard
                    showsTutorialInitially,
                    !didApplyInitialTutorialPresentation
                else { return }
                didApplyInitialTutorialPresentation = true
                await Task.yield()
                isShowingTutorial = true
            }
            .overlay(alignment: .bottom) {
                feedbackOverlay
            }
            .confirmationDialog(
                "プロフィール画像を削除しますか？",
                isPresented: $isShowingAvatarDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("画像を削除", role: .destructive) {
                    Task {
                        await store.removeAvatar()
                        showAvatarFeedbackIfNeeded()
                    }
                }
                Button("キャンセル", role: .cancel) {}
            } message: {
                Text("画像未設定の状態へ戻り、ここにゃんが表示されます。")
            }
            .confirmationDialog(
                "ログアウトしますか？",
                isPresented: $isShowingLogoutConfirmation,
                titleVisibility: .visible
            ) {
                Button("ログアウト", role: .destructive, action: onLogout)
                Button("キャンセル", role: .cancel) {}
            } message: {
                Text("いつでも同じアカウントで戻ってこられます。")
            }
            .navigationDestination(
                isPresented: Binding(
                    get: { deepLink != nil },
                    set: { if !$0 { deepLink = nil } }
                )
            ) {
                deepLinkDestination
            }
        }
    }

    private func profileContent(_ profile: Profile) -> some View {
        VStack(spacing: 24) {
            if store.error != nil && !isShowingNameEditor {
                inlineProfileError
            }
            if store.avatarError != nil {
                inlineAvatarError
            }

            profileHeader(profile)

            if store.pendingAvatarData != nil {
                pendingAvatarActions
            }

            settingsContent(profile)
        }
    }

    private func profileHeader(_ profile: Profile) -> some View {
        let avatarData = store.pendingAvatarData ?? store.avatarData
        let isAvatarLoading = store.isAvatarLoading || store.isAvatarSaving

        return VStack(spacing: 11) {
            PhotosPicker(
                selection: $selectedPhoto,
                matching: .images,
                photoLibrary: .shared()
            ) {
                ZStack(alignment: .bottomTrailing) {
                    ProfileAvatarImageView(
                        data: avatarData,
                        isLoading: isAvatarLoading
                    )
                        .frame(width: 106, height: 106)
                        .clipShape(Circle())
                        .overlay {
                            Circle()
                                .stroke(AppColors.primary.opacity(0.5), lineWidth: 2)
                        }
                        .shadow(color: AppColors.shadow, radius: 8, y: 4)

                    Image(systemName: "pencil")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 32, height: 32)
                        .background(AppColors.primary)
                        .clipShape(Circle())
                        .overlay {
                            Circle().stroke(AppColors.cardBackground, lineWidth: 3)
                        }
                        .accessibilityHidden(true)
                }
                .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .disabled(store.isAvatarLoading || store.isAvatarSaving)
            .accessibilityLabel("プロフィール画像を選ぶ")
            .onChange(of: selectedPhoto) { _, item in
                guard let item else { return }
                Task {
                    await loadSelectedPhoto(item)
                    selectedPhoto = nil
                }
            }

            Text(profile.displayName)
                .font(.system(size: 25, weight: .bold, design: .rounded))
                .foregroundStyle(AppColors.textPrimary)
                .lineLimit(2)
                .minimumScaleFactor(0.75)
                .multilineTextAlignment(.center)

            Text(email ?? "メールアドレス未設定")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(AppColors.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            friendCodeView(profile.friendCode)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 22)
        .padding(.vertical, 24)
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 26))
        .overlay {
            RoundedRectangle(cornerRadius: 26)
                .stroke(AppColors.border, lineWidth: 1.2)
        }
        .shadow(color: AppColors.shadow, radius: 12, y: 5)
    }

    private func friendCodeView(_ friendCode: String) -> some View {
        VStack(spacing: 7) {
            Text("フレンドコード")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(AppColors.textSecondary)

            HStack(spacing: 10) {
                Text(friendCode)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .tracking(2.4)
                    .foregroundStyle(AppColors.primaryDark)
                    .textSelection(.enabled)

                Button {
                    copyFriendCode(friendCode)
                } label: {
                    Image(systemName: "doc.on.doc.fill")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(AppColors.primaryDark)
                        .frame(width: 38, height: 38)
                        .background(AppColors.cardBackground)
                        .clipShape(Circle())
                        .overlay {
                            Circle().stroke(AppColors.border, lineWidth: 1)
                        }
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("フレンドコードをコピー")
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(AppColors.primarySoft.opacity(0.85))
        .clipShape(RoundedRectangle(cornerRadius: 17))
    }

    private var pendingAvatarActions: some View {
        VStack(spacing: 12) {
            HStack(spacing: 11) {
                Image(systemName: "photo.badge.checkmark")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(AppColors.primaryDark)

                VStack(alignment: .leading, spacing: 3) {
                    Text("この画像を使いますか？")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(AppColors.textPrimary)
                    Text("保存するまで現在の画像は変更されません")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(AppColors.textSecondary)
                }
                Spacer(minLength: 0)
            }

            HStack(spacing: 10) {
                Button("選び直す") {
                    store.discardPendingAvatar()
                }
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(AppColors.primaryDark)
                .frame(maxWidth: .infinity)
                .frame(height: 46)
                .background(AppColors.primarySoft)
                .clipShape(Capsule())

                Button {
                    Task {
                        await store.savePendingAvatar()
                        showAvatarFeedbackIfNeeded()
                    }
                } label: {
                    HStack(spacing: 7) {
                        if store.isAvatarSaving {
                            ProgressView()
                                .tint(.white)
                        }
                        Text(store.isAvatarSaving ? "保存中…" : "保存する")
                    }
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                    .background(AppColors.primary)
                    .clipShape(Capsule())
                }
                .disabled(store.isAvatarSaving)
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .stroke(AppColors.border, lineWidth: 1)
        }
    }

    private func settingsContent(_ profile: Profile) -> some View {
        VStack(spacing: 22) {
            ProfileSettingsSection(title: "プロフィール") {
                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    ProfileSettingsRow(
                        title: "プロフィール画像変更",
                        systemImage: "photo.fill"
                    )
                }
                .buttonStyle(.plain)

                if profile.avatarKey != nil || store.avatarData != nil {
                    ProfileSettingsDivider()

                    Button {
                        isShowingAvatarDeleteConfirmation = true
                    } label: {
                        ProfileSettingsRow(
                            title: "画像を削除",
                            systemImage: "trash",
                            tint: .red,
                            showsChevron: false,
                            isDestructive: true
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(store.isAvatarSaving)
                }

                ProfileSettingsDivider()

                Button {
                    isShowingNameEditor = true
                } label: {
                    ProfileSettingsRow(
                        title: "表示名変更",
                        systemImage: "pencil"
                    )
                }
                .buttonStyle(.plain)
            }

            ProfileSettingsSection(title: "つながり") {
                NavigationLink {
                    FriendListView(
                        store: friendStore,
                        profile: profile,
                        clipboard: clipboard,
                        currentAvatarData: store.avatarData
                    )
                } label: {
                    ProfileSettingsRow(
                        title: "フレンド",
                        systemImage: "person.2.fill",
                        detail: "\(friendStore.friends.count)人"
                    )
                }
                .buttonStyle(.plain)
            }

            ProfileSettingsSection(title: "アカウント") {
                Button {
                    isShowingLogoutConfirmation = true
                } label: {
                    ProfileSettingsRow(
                        title: isAuthLoading ? "ログアウト中…" : "ログアウト",
                        systemImage: "rectangle.portrait.and.arrow.right",
                        tint: .red,
                        showsChevron: false,
                        isDestructive: true
                    )
                }
                .buttonStyle(.plain)
                .disabled(isAuthLoading)
            }

            supportSection
            appSection
        }
    }

    private var supportSection: some View {
        ProfileSettingsSection(title: "サポート") {
            Button {
                isShowingTutorial = true
            } label: {
                ProfileSettingsRow(
                    title: "使い方を見る",
                    systemImage: "book.fill",
                    detail: "使い方を確認"
                )
            }
            .buttonStyle(.plain)

            ProfileSettingsDivider()

            informationLink(
                title: "お問い合わせ",
                systemImage: "envelope.fill",
                message: "お問い合わせ窓口は現在準備中です。もうしばらくお待ちください。"
            )
            ProfileSettingsDivider()
            informationLink(
                title: "利用規約",
                systemImage: "doc.text.fill",
                message: "利用規約は正式公開までに、この画面から確認できるようになります。"
            )
            ProfileSettingsDivider()
            informationLink(
                title: "プライバシーポリシー",
                systemImage: "hand.raised.fill",
                message: "プライバシーポリシーは正式公開までに、この画面から確認できるようになります。"
            )
        }
    }

    private var appSection: some View {
        ProfileSettingsSection(title: "アプリ") {
            ProfileSettingsRow(
                title: "バージョン",
                systemImage: "info.circle.fill",
                detail: appVersion,
                showsChevron: false
            )
            ProfileSettingsDivider()
            informationLink(
                title: "ライセンス",
                systemImage: "checkmark.seal.fill",
                message: "アプリで利用しているライセンス情報を、正式公開までに掲載します。"
            )
        }
    }

    private func informationLink(
        title: String,
        systemImage: String,
        message: String
    ) -> some View {
        NavigationLink {
            ProfileInformationView(title: title, message: message)
        } label: {
            ProfileSettingsRow(title: title, systemImage: systemImage)
        }
        .buttonStyle(.plain)
    }

    private var loadingContent: some View {
        VStack(spacing: 16) {
            Image("cat_default")
                .resizable()
                .scaledToFit()
                .frame(width: 124, height: 104)
                .accessibilityHidden(true)
            ProgressView().tint(AppColors.primary)
            Text("あなたのお部屋を準備しています…")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(AppColors.textSecondary)
        }
        .padding(.vertical, 80)
    }

    private var unavailableContent: some View {
        VStack(spacing: 16) {
            Image("cat_sad")
                .resizable()
                .scaledToFit()
                .frame(width: 132, height: 112)
                .accessibilityHidden(true)
            Text(store.error == nil
                 ? "プロフィールがまだありません"
                 : "プロフィールを読み込めませんでした")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(AppColors.textPrimary)
            Text("もう一度読み込むと、表示できることがあります")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center)
            Button("もう一度読み込む") {
                Task { await store.reloadProfile() }
            }
            .font(.system(size: 15, weight: .bold, design: .rounded))
            .foregroundStyle(AppColors.primaryDark)
            .padding(.horizontal, 20)
            .frame(height: 46)
            .background(AppColors.primarySoft)
            .clipShape(Capsule())
            .buttonStyle(.plain)
        }
        .padding(.vertical, 72)
    }

    private var inlineProfileError: some View {
        inlineError(
            message: store.error?.localizedDescription
                ?? "プロフィールを更新できませんでした"
        ) {
            store.clearError()
        }
    }

    private var inlineAvatarError: some View {
        inlineError(
            message: store.avatarError?.localizedDescription
                ?? "プロフィール画像を更新できませんでした"
        ) {
            store.clearAvatarError()
        }
    }

    private func inlineError(
        message: String,
        onClose: @escaping () -> Void
    ) -> some View {
        HStack(spacing: 12) {
            Image("cat_sad")
                .resizable()
                .scaledToFit()
                .frame(width: 50, height: 44)
                .accessibilityHidden(true)
            Text(message)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(AppColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
            Button("閉じる", action: onClose)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(AppColors.primaryDark)
        }
        .padding(14)
        .background(AppColors.pastelPink.opacity(0.42))
        .clipShape(RoundedRectangle(cornerRadius: 17))
    }

    @ViewBuilder
    private var feedbackOverlay: some View {
        if showsCopyMessage {
            feedbackCapsule(image: "cat_happy", message: "コピーしました！")
        } else if showsAvatarMessage {
            feedbackCapsule(
                image: "cat_happy",
                message: store.avatarFeedback == .removed
                    ? "プロフィール画像を削除しました！"
                    : "プロフィール画像を更新しました！"
            )
        }
    }

    private func feedbackCapsule(image: String, message: String) -> some View {
        HStack(spacing: 10) {
            Image(image)
                .resizable()
                .scaledToFit()
                .frame(width: 42, height: 38)
                .accessibilityHidden(true)
            Text(message)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(AppColors.primaryDark)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 9)
        .background(AppColors.cardBackground)
        .clipShape(Capsule())
        .overlay { Capsule().stroke(AppColors.border, lineWidth: 1) }
        .shadow(color: AppColors.shadow, radius: 9, y: 4)
        .padding(.bottom, 92)
        .transition(.opacity.combined(with: .scale(scale: 0.96)))
    }

    @ViewBuilder
    private var deepLinkDestination: some View {
        switch deepLink {
        case let .incomingFriendRequest(id):
            FriendRequestDetailView(requestID: id, store: friendStore)
        case let .friend(id):
            FriendDetailView(friendID: id, store: friendStore)
        default:
            ContentUnavailableView(
                "対象の情報を表示できません",
                systemImage: "exclamationmark.triangle"
            )
        }
    }

    private var appVersion: String {
        Bundle.main.object(
            forInfoDictionaryKey: "CFBundleShortVersionString"
        ) as? String ?? "1.0"
    }

    private func loadSelectedPhoto(_ item: PhotosPickerItem) async {
        do {
            guard let data = try await item.loadTransferable(type: Data.self) else {
                throw AppError.profileAvatarInvalid
            }
            await store.prepareAvatar(from: data)
        } catch {
            store.reportAvatarSelectionError(error)
        }
    }

    private func copyFriendCode(_ friendCode: String) {
        clipboard.copy(friendCode)
        withAnimation(.easeInOut(duration: 0.2)) {
            showsCopyMessage = true
        }
        Task {
            try? await Task.sleep(for: .seconds(1.8))
            withAnimation(.easeInOut(duration: 0.2)) {
                showsCopyMessage = false
            }
        }
    }

    private func showAvatarFeedbackIfNeeded() {
        guard store.avatarFeedback != nil else { return }
        withAnimation(.easeInOut(duration: 0.2)) {
            showsAvatarMessage = true
        }
        Task {
            try? await Task.sleep(for: .seconds(2))
            withAnimation(.easeInOut(duration: 0.2)) {
                showsAvatarMessage = false
            }
            store.clearAvatarFeedback()
        }
    }
}

private struct ProfileAvatarImageView: View {
    let data: Data?
    let isLoading: Bool

    var body: some View {
        ZStack {
            AppColors.primarySoft

            if let data, let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .accessibilityLabel("プロフィール画像")
            } else {
                Image("cat_default")
                    .resizable()
                    .scaledToFit()
                    .padding(7)
                    .accessibilityLabel("プロフィール画像は未設定です")
            }

            if isLoading {
                ProgressView()
                    .tint(AppColors.primaryDark)
                    .padding(12)
                    .background(AppColors.cardBackground)
                    .clipShape(Circle())
                    .accessibilityLabel("プロフィール画像を読み込み中")
            }
        }
        .clipped()
    }
}

#Preview("画像未設定") {
    ProfilePreviewFactory.make()
}

#Preview("画像設定済み") {
    ProfilePreviewFactory.make(avatarData: ProfilePreviewFactory.sampleAvatarData)
}

#Preview("画像読込中") {
    ProfilePreviewFactory.make(isAvatarLoading: true)
}

#Preview("アップロード中") {
    ProfilePreviewFactory.make(
        pendingAvatarData: ProfilePreviewFactory.sampleAvatarData,
        isAvatarSaving: true
    )
}

#Preview("アップロード成功") {
    ProfilePreviewFactory.make(
        avatarData: ProfilePreviewFactory.sampleAvatarData,
        avatarFeedback: .saved
    )
}

#Preview("アップロード失敗") {
    ProfilePreviewFactory.make(
        avatarError: .profileAvatarUploadFailed
    )
}

#Preview("画像削除確認") {
    ProfilePreviewFactory.make(
        profile: ProfilePreviewFactory.profileWithAvatar,
        avatarData: ProfilePreviewFactory.sampleAvatarData,
        showsAvatarDeleteConfirmationInitially: true
    )
}

#Preview("長い表示名") {
    ProfilePreviewFactory.make(
        profile: Profile(
            id: UUID(),
            displayName: "こころチケットが大好きなやまもとさん",
            friendCode: "KRTK7M2P",
            avatarKey: nil,
            createdAt: .now,
            updatedAt: .now
        )
    )
}

#Preview("Dark Mode") {
    ProfilePreviewFactory.make()
        .preferredColorScheme(.dark)
}

#Preview("iPhone SE", traits: .fixedLayout(width: 375, height: 667)) {
    ProfilePreviewFactory.make()
}

@MainActor
private enum ProfilePreviewFactory {
    static var profileWithAvatar: Profile {
        var profile = Profile.preview
        profile.avatarKey = "\(profile.id.uuidString.lowercased())/avatar-preview.jpg"
        return profile
    }

    static var sampleAvatarData: Data? {
        let renderer = UIGraphicsImageRenderer(
            size: CGSize(width: 320, height: 320)
        )
        return renderer.image { context in
            UIColor.systemTeal.setFill()
            context.cgContext.fill(
                CGRect(x: 0, y: 0, width: 320, height: 320)
            )
            let symbol = UIImage(
                systemName: "person.fill",
                withConfiguration: UIImage.SymbolConfiguration(pointSize: 150)
            )?.withTintColor(.white, renderingMode: .alwaysOriginal)
            symbol?.draw(in: CGRect(x: 85, y: 85, width: 150, height: 150))
        }
        .jpegData(compressionQuality: 0.8)
    }

    static func make(
        profile: Profile? = .preview,
        avatarData: Data? = nil,
        pendingAvatarData: Data? = nil,
        isAvatarLoading: Bool = false,
        isAvatarSaving: Bool = false,
        avatarError: AppError? = nil,
        avatarFeedback: ProfileAvatarFeedback? = nil,
        showsAvatarDeleteConfirmationInitially: Bool = false
    ) -> some View {
        let profileStore = ProfileStore(
            repository: InMemoryProfileRepository(
                profile: profile,
                avatarData: avatarData
            ),
            profile: profile,
            isLoading: false,
            avatarData: avatarData,
            pendingAvatarData: pendingAvatarData,
            isAvatarLoading: isAvatarLoading,
            isAvatarSaving: isAvatarSaving,
            avatarError: avatarError,
            avatarFeedback: avatarFeedback
        )

        return ProfileView(
            store: profileStore,
            friendStore: FriendStore(
                repository: InMemoryFriendRepository(friends: MockFriends.items)
            ),
            email: "preview@example.com",
            isAuthLoading: false,
            clipboard: PreviewClipboardService(),
            showsAvatarDeleteConfirmationInitially: showsAvatarDeleteConfirmationInitially,
            onLogout: {}
        )
    }
}
