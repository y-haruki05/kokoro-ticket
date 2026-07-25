import SwiftUI

struct TicketStatusLabel: View {
    let status: TicketUsageStatus

    var body: some View {
        Text(status.rawValue)
            .font(.system(size: 11, weight: .bold, design: .rounded))
            .foregroundStyle(
                status == .unused
                    ? AppColors.primaryDark
                    : AppColors.textSecondary
            )
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                status == .unused
                    ? AppColors.primarySoft
                    : AppColors.background
            )
            .clipShape(Capsule())
            .overlay {
                Capsule()
                    .stroke(
                        status == .unused
                            ? AppColors.primary
                            : AppColors.border,
                        lineWidth: 1
                    )
            }
    }
}

#Preview {
    HStack {
        TicketStatusLabel(status: .unused)
        TicketStatusLabel(status: .used)
    }
    .padding()
}
