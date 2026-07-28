import SwiftUI

struct TicketListSegmentedControl: View {
    @Binding var selection: TicketStatus
    @Namespace private var selectionAnimation

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(TicketStatus.allCases) { status in
                        Button {
                            withAnimation(.easeInOut(duration: 0.18)) {
                                selection = status
                                proxy.scrollTo(status, anchor: .center)
                            }
                        } label: {
                            Text(status.displayName)
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundStyle(
                                    selection == status
                                        ? Color.white
                                        : AppColors.textSecondary
                                )
                                .padding(.horizontal, 16)
                                .frame(height: 40)
                                .background {
                                    if selection == status {
                                        Capsule()
                                            .fill(AppColors.primary)
                                            .matchedGeometryEffect(
                                                id: "selectedTicketCategory",
                                                in: selectionAnimation
                                            )
                                    } else {
                                        Capsule()
                                            .fill(AppColors.primarySoft.opacity(0.55))
                                    }
                                }
                                .clipShape(Capsule())
                                .overlay {
                                    Capsule()
                                        .stroke(
                                            selection == status
                                                ? AppColors.primary
                                                : AppColors.border,
                                            lineWidth: 1
                                        )
                                }
                                .contentShape(Capsule())
                        }
                        .buttonStyle(.plain)
                        .id(status)
                        .accessibilityAddTraits(
                            selection == status ? .isSelected : []
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 4)
            }
            .onAppear {
                proxy.scrollTo(selection, anchor: .center)
            }
            .onChange(of: selection) { _, newValue in
                withAnimation(.easeInOut(duration: 0.18)) {
                    proxy.scrollTo(newValue, anchor: .center)
                }
            }
        }
    }
}

#Preview {
    @Previewable @State var selection = TicketStatus.draft

    TicketListSegmentedControl(selection: $selection)
        .padding(.vertical)
        .background(AppColors.background)
}
