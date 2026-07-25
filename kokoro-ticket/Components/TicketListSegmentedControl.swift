import SwiftUI

struct TicketListSegmentedControl: View {
    @Binding var selection: TicketListCategory

    var body: some View {
        HStack(spacing: 0) {
            ForEach(TicketListCategory.allCases) { category in
                Button {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        selection = category
                    }
                } label: {
                    VStack(spacing: 10) {
                        Text(category.rawValue)
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                selection == category
                                    ? AppColors.primary
                                    : AppColors.textSecondary
                            )

                        Capsule()
                            .fill(
                                selection == category
                                    ? AppColors.primary
                                    : Color.clear
                            )
                            .frame(height: 3)
                    }
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(
                    selection == category ? .isSelected : []
                )
            }
        }
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(AppColors.border.opacity(0.55))
                .frame(height: 1)
        }
    }
}

#Preview {
    @Previewable @State var selection = TicketListCategory.received

    TicketListSegmentedControl(selection: $selection)
        .padding()
}
