import SwiftUI

struct TicketStatusLabel: View {
    let status: TicketStatus
    var title: String? = nil

    var body: some View {
        Text(title ?? status.statusLabel)
            .font(.system(size: 11, weight: .bold, design: .rounded))
            .foregroundStyle(status == .completed ? AppColors.textSecondary : AppColors.primaryDark)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(status == .completed ? AppColors.background : AppColors.primarySoft)
            .clipShape(Capsule())
            .overlay {
                Capsule()
                    .stroke(
                        status == .completed ? AppColors.border : AppColors.primary,
                        lineWidth: 1
                    )
            }
    }
}

#Preview {
    HStack {
        ForEach(TicketStatus.allCases) { status in
            TicketStatusLabel(status: status)
        }
    }
    .padding()
}
