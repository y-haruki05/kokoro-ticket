import SwiftUI

struct FriendSearchView: View {
    let store: FriendStore
    @State private var friendCode = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Text("8文字のフレンドコードを入力してください")
                    .font(.system(size: 15, design: .rounded))
                    .foregroundStyle(AppColors.textSecondary)

                TextField("例：KRTK7M2P", text: $friendCode)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .tracking(2)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled(true)
                    .padding(.horizontal, 18)
                    .frame(height: 56)
                    .background(AppColors.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .overlay { RoundedRectangle(cornerRadius: 18).stroke(AppColors.border, lineWidth: 1.5) }
                    .onChange(of: friendCode) { _, newValue in
                        friendCode = String(
                            newValue.uppercased().filter { $0.isASCII && $0.isLetter || "23456789".contains($0) }
                                .filter { !"OI".contains($0) }
                                .prefix(8)
                        )
                    }

                PrimaryActionButton(
                    title: "検索",
                    isLoading: store.isSearching,
                    isDisabled: friendCode.count != 8
                ) {
                    Task { await store.search(friendCode: friendCode) }
                }

                if let result = store.searchResult {
                    resultCard(result)
                }
            }
            .padding(20)
        }
        .background(AppColors.background)
        .navigationTitle("フレンドを追加")
        .navigationBarTitleDisplayMode(.inline)
        .friendErrorAlert(store: store)
    }

    private func resultCard(_ result: FriendSearchResult) -> some View {
        VStack(spacing: 16) {
            FriendProfileRow(profile: result.profile)

            switch result.relationship {
            case .none:
                PrimaryActionButton(title: "申請する", isLoading: store.isLoading) {
                    Task { await store.sendRequest() }
                }
            case .outgoingPending:
                stateLabel("申請中")
            case .friend:
                stateLabel("フレンドです")
            case .incomingPending:
                NavigationLink {
                    IncomingFriendRequestsView(store: store)
                } label: {
                    stateLabel("申請を確認")
                }
                .buttonStyle(.plain)
            }
        }
        .padding(18)
        .background(AppColors.primarySoft.opacity(0.55))
        .clipShape(RoundedRectangle(cornerRadius: 22))
    }

    private func stateLabel(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 16, weight: .bold, design: .rounded))
            .foregroundStyle(AppColors.primaryDark)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(AppColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 17))
            .overlay { RoundedRectangle(cornerRadius: 17).stroke(AppColors.border, lineWidth: 1.5) }
    }
}

#Preview("検索結果あり") {
    NavigationStack {
        FriendSearchView(
            store: FriendStore(
                repository: InMemoryFriendRepository(),
                searchResult: FriendPreviewData.searchResult
            )
        )
    }
}

#Preview("申請済み") {
    NavigationStack {
        FriendSearchView(
            store: FriendStore(
                repository: InMemoryFriendRepository(),
                searchResult: FriendSearchResult(
                    profile: FriendPreviewData.otherProfile,
                    relationship: .outgoingPending
                )
            )
        )
    }
}

#Preview("相手から申請あり") {
    NavigationStack {
        FriendSearchView(
            store: FriendStore(
                repository: InMemoryFriendRepository(),
                searchResult: FriendSearchResult(
                    profile: FriendPreviewData.otherProfile,
                    relationship: .incomingPending
                )
            )
        )
    }
}

#Preview("検索エラー") {
    NavigationStack {
        FriendSearchView(
            store: FriendStore(
                repository: InMemoryFriendRepository(),
                error: .friendNotFound
            )
        )
    }
}
