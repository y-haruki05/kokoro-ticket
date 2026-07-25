import SwiftUI

struct TornTicketView: View {
    let ticket: TicketListItem
    let isTorn: Bool
    let isLeftReleased: Bool
    let isRightReleased: Bool
    let stretchX: CGFloat
    let stretchY: CGFloat
    let opacity: Double

    var body: some View {
        GeometryReader { proxy in
            if isTorn {
                tornHalves(in: proxy.size)
            } else {
                TicketUsageTicketView(ticket: ticket)
                    .scaleEffect(x: stretchX, y: stretchY)
            }
        }
        .opacity(opacity)
    }

    private func tornHalves(in size: CGSize) -> some View {
        ZStack {
            ticketHalf(.left)
                .offset(
                    x: isLeftReleased ? -size.width * 0.27 : 0,
                    y: isLeftReleased ? size.height * 0.22 : 0
                )
                .rotationEffect(.degrees(isLeftReleased ? -9 : 0))
                .scaleEffect(isLeftReleased ? 0.90 : 1)

            ticketHalf(.right)
                .offset(
                    x: isRightReleased ? size.width * 0.27 : 0,
                    y: isRightReleased ? size.height * 0.25 : 0
                )
                .rotationEffect(.degrees(isRightReleased ? 10 : 0))
                .scaleEffect(isRightReleased ? 0.89 : 1)
        }
    }

    private func ticketHalf(_ side: TicketHalfSide) -> some View {
        TicketUsageTicketView(ticket: ticket)
            .mask(TicketHalfShape(side: side))
            .overlay {
                TicketTearEdgeShape(side: side)
                    .stroke(
                        AppColors.primary.opacity(0.75),
                        style: StrokeStyle(lineWidth: 1.5, lineCap: .round)
                    )
            }
    }
}

#Preview {
    TornTicketView(
        ticket: MockTicketListItems.items[0],
        isTorn: true,
        isLeftReleased: true,
        isRightReleased: true,
        stretchX: 1,
        stretchY: 1,
        opacity: 1
    )
    .frame(width: 330, height: 230)
    .padding(60)
    .background(AppColors.primarySoft)
}
