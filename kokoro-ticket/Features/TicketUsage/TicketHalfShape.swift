import SwiftUI

enum TicketHalfSide {
    case left
    case right
}

struct TicketHalfShape: Shape {
    let side: TicketHalfSide

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let centerX = rect.midX
        let segmentCount = 13

        switch side {
        case .left:
            path.move(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: centerX, y: rect.minY))

            for index in 1...segmentCount {
                path.addLine(
                    to: tearPoint(
                        index: index,
                        segmentCount: segmentCount,
                        centerX: centerX,
                        rect: rect
                    )
                )
            }

            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))

        case .right:
            path.move(to: CGPoint(x: centerX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: centerX, y: rect.maxY))

            for index in stride(from: segmentCount - 1, through: 0, by: -1) {
                path.addLine(
                    to: tearPoint(
                        index: index,
                        segmentCount: segmentCount,
                        centerX: centerX,
                        rect: rect
                    )
                )
            }
        }

        path.closeSubpath()
        return path
    }

    private func tearPoint(
        index: Int,
        segmentCount: Int,
        centerX: CGFloat,
        rect: CGRect
    ) -> CGPoint {
        let y = rect.minY + rect.height * CGFloat(index) / CGFloat(segmentCount)
        let offsets: [CGFloat] = [0, -7, 6, -4, 8, -6, 4]
        let x = centerX + offsets[index % offsets.count]
        return CGPoint(x: x, y: y)
    }
}

struct TicketTearEdgeShape: Shape {
    let side: TicketHalfSide

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let centerX = rect.midX
        let segmentCount = 13
        let offsets: [CGFloat] = [0, -7, 6, -4, 8, -6, 4]

        path.move(to: CGPoint(x: centerX, y: rect.minY))

        for index in 1...segmentCount {
            let y = rect.minY + rect.height * CGFloat(index) / CGFloat(segmentCount)
            let x = centerX + offsets[index % offsets.count]
            path.addLine(to: CGPoint(x: x, y: y))
        }

        return path
    }
}
