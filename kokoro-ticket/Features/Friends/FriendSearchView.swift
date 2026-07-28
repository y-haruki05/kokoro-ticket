import SwiftUI

struct FriendSearchView: View {
    let store: FriendStore
    var currentProfile: Profile? = nil

    @State private var friendCode = ""
    @FocusState private var isCodeFocused: Bool

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                searchCard
                resultContent
            }
            .padding(.horizontal, 20)
            .padding(.top, 14)
            .padding(.bottom, 40)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(AppColors.background)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("フレンドを追加")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(AppColors.textPrimary)
            }
        }
        .toolbarBackground(AppColors.background, for: .navigationBar)
        .toolbarColorScheme(.light, for: .navigationBar)
        .friendErrorAlert(store: store)
        .onDisappear {
            store.clearSearch()
        }
    }

    private var searchCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(AppColors.primaryDark)
                    .frame(width: 46, height: 46)
                    .background(AppColors.primarySoft)
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 3) {
                    Text("フレンドコードで検索")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(AppColors.textPrimary)
                    Text("8文字のコードを入力してください")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(AppColors.textSecondary)
                }
            }

            TextField("例：KRTK7M2P", text: $friendCode)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .tracking(2)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled(true)
                .textContentType(.none)
                .submitLabel(.search)
                .focused($isCodeFocused)
                .padding(.horizontal, 18)
                .frame(height: 56)
                .background(AppColors.primarySoft.opacity(0.45))
                .clipShape(RoundedRectangle(cornerRadius: 17, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 17, style: .continuous)
                        .stroke(
                            isCodeFocused ? AppColors.primary : AppColors.border,
                            lineWidth: isCodeFocused ? 1.7 : 1
                        )
                }
                .onSubmit { search() }
                .onChange(of: friendCode) { _, newValue in
                    let normalized = String(
                        newValue
                            .uppercased()
                            .filter {
                                ($0.isASCII && $0.isLetter || "23456789".contains($0))
                                    && !"OI".contains($0)
                            }
                            .prefix(8)
                    )
                    if normalized != friendCode {
                        friendCode = normalized
                    }
                    if store.hasSearched {
                        store.clearSearch()
                    }
                }

            PrimaryActionButton(
                title: "検索",
                isLoading: store.isSearching,
                isDisabled: friendCode.count != 8
            ) {
                search()
            }
        }
        .padding(20)
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(AppColors.border, lineWidth: 1.2)
        }
        .shadow(color: AppColors.shadow.opacity(0.5), radius: 10, y: 4)
    }

    @ViewBuilder
    private var resultContent: some View {
        if let result = store.searchResult {
            resultCard(result)
        } else if store.hasSearched && !store.isSearching {
            FriendEmptyStateView(
                imageName: "cat_sad",
                title: "見つかりませんでした。",
                message: "コードをもう一度確認してみてください。"
            )
        }
    }

    private func resultCard(_ result: FriendSearchResult) -> some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("検索結果")
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(AppColors.textPrimary)

            FriendProfileRow(profile: result.profile, store: store)

            relationshipAction(result.relationship)
        }
        .padding(18)
        .background(AppColors.primarySoft.opacity(0.45))
        .clipShape(RoundedRectangle(cornerRadius: 23, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 23, style: .continuous)
                .stroke(AppColors.border.opacity(0.8), lineWidth: 1)
        }
        .transition(.opacity.combined(with: .scale(scale: 0.98)))
    }

    @ViewBuilder
    private func relationshipAction(_ relationship: FriendSearchRelationship) -> some View {
        switch relationship {
        case .none:
            PrimaryActionButton(title: "フレンドになる", isLoading: store.isLoading) {
                Task { await store.sendRequest() }
            }
        case .outgoingPending:
            relationshipLabel("申請済み", icon: "paperplane.fill")
        case .friend:
            relationshipLabel("フレンドです", icon: "person.2.fill")
        case .selfProfile:
            relationshipLabel("自分です", icon: "person.crop.circle.fill")
        case .incomingPending:
            NavigationLink {
                IncomingFriendRequestsView(store: store)
            } label: {
                relationshipLabel("申請を確認", icon: "tray.and.arrow.down.fill")
            }
            .buttonStyle(.plain)
        }
    }

    private func relationshipLabel(_ title: String, icon: String) -> some View {
        Label(title, systemImage: icon)
            .font(.system(size: 15, weight: .bold, design: .rounded))
            .foregroundStyle(AppColors.primaryDark)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(AppColors.cardBackground)
            .clipShape(Capsule())
            .overlay { Capsule().stroke(AppColors.border, lineWidth: 1.2) }
    }

    private func search() {
        guard friendCode.count == 8, !store.isSearching else { return }
        isCodeFocused = false
        Task {
            await store.search(
                friendCode: friendCode,
                currentProfile: currentProfile
            )
        }
    }
}

#if DEBUG
#Preview("検索結果") {
    NavigationStack {
        FriendSearchView(
            store: FriendStore(
                repository: InMemoryFriendRepository(),
                searchResult: FriendPreviewData.searchResult
            )
        )
    }
}

#Preview("検索結果なし") {
    NavigationStack {
        FriendSearchView(
            store: FriendStore(
                repository: InMemoryFriendRepository(),
                hasSearched: true
            )
        )
    }
}
#endif
