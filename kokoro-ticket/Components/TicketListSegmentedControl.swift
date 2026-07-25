import SwiftUI

struct TicketListSegmentedControl: View {
    @Binding var selection: TicketStatus

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(TicketStatus.allCases) { status in
                    Button {
                        withAnimation(.easeInOut(duration: 0.18)) {
                            selection = status
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
                            .frame(height: 42)
                            .background(
                                selection == status
                                    ? AppColors.primary
                                    : AppColors.cardBackground
                            )
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
                    .accessibilityAddTraits(
                        selection == status ? .isSelected : []
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 2)
        }
    }
}

#Preview {
    @Previewable @State var selection = TicketStatus.draft

    TicketListSegmentedControl(selection: $selection)
        .padding(.vertical)
        .background(AppColors.background)
}
