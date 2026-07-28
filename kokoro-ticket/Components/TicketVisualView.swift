import SwiftUI

enum TicketVisualSize {
    case large
    case compact
}

struct TicketShape: Shape {
    var cornerRadius: CGFloat = 18
    var notchRadius: CGFloat = 10

    func path(in rect: CGRect) -> Path {
        let radius = min(cornerRadius, rect.height * 0.18)
        let notch = min(notchRadius, rect.height * 0.12)
        let middleY = rect.midY

        var path = Path()
        path.move(to: CGPoint(x: rect.minX + radius, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.minY))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY + radius),
            control: CGPoint(x: rect.maxX, y: rect.minY)
        )
        path.addLine(to: CGPoint(x: rect.maxX, y: middleY - notch))
        path.addCurve(
            to: CGPoint(x: rect.maxX, y: middleY + notch),
            control1: CGPoint(x: rect.maxX - notch, y: middleY - notch * 0.65),
            control2: CGPoint(x: rect.maxX - notch, y: middleY + notch * 0.65)
        )
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - radius))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX - radius, y: rect.maxY),
            control: CGPoint(x: rect.maxX, y: rect.maxY)
        )
        path.addLine(to: CGPoint(x: rect.minX + radius, y: rect.maxY))
        path.addQuadCurve(
            to: CGPoint(x: rect.minX, y: rect.maxY - radius),
            control: CGPoint(x: rect.minX, y: rect.maxY)
        )
        path.addLine(to: CGPoint(x: rect.minX, y: middleY + notch))
        path.addCurve(
            to: CGPoint(x: rect.minX, y: middleY - notch),
            control1: CGPoint(x: rect.minX + notch, y: middleY + notch * 0.65),
            control2: CGPoint(x: rect.minX + notch, y: middleY - notch * 0.65)
        )
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + radius))
        path.addQuadCurve(
            to: CGPoint(x: rect.minX + radius, y: rect.minY),
            control: CGPoint(x: rect.minX, y: rect.minY)
        )
        path.closeSubpath()
        return path
    }
}

struct TicketPerforationView: View {
    var body: some View {
        Rectangle()
            .fill(AppColors.primary.opacity(0.55))
            .frame(width: 1)
            .mask {
                VStack(spacing: 5) {
                    ForEach(0..<18, id: \.self) { _ in
                        Capsule()
                            .frame(width: 1, height: 4)
                    }
                }
            }
            .accessibilityHidden(true)
    }
}

struct TicketVisualView: View {
    let title: String
    let message: String
    let illustration: TicketIllustration?
    let design: TicketDesign
    var senderName: String?
    var date: Date?
    var size: TicketVisualSize = .large

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                TicketShape(
                    cornerRadius: size == .large ? 20 : 14,
                    notchRadius: size == .large ? 11 : 8
                )
                .fill(design.backgroundColor.color)

                HStack(spacing: 0) {
                    mainTicket
                        .frame(width: proxy.size.width * 0.82)

                    ZStack {
                        TicketPerforationView()
                            .frame(maxHeight: .infinity)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        stub
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .padding(.horizontal, size == .large ? 14 : 9)
                .padding(.vertical, size == .large ? 12 : 8)
                .clipShape(
                    TicketShape(
                        cornerRadius: size == .large ? 20 : 14,
                        notchRadius: size == .large ? 11 : 8
                    )
                )

                ticketBorder
            }
        }
        .aspectRatio(size == .large ? 1.95 : 2.08, contentMode: .fit)
        .shadow(color: AppColors.shadow.opacity(0.8), radius: size == .large ? 10 : 6, y: 4)
        .contentShape(TicketShape())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
    }

    private var mainTicket: some View {
        HStack(spacing: size == .large ? 13 : 8) {
            Image(illustration?.assetName ?? "cat_ticket")
                .resizable()
                .scaledToFit()
                .frame(
                    width: size == .large ? 92 : 48,
                    height: size == .large ? 92 : 48
                )
                .clipShape(RoundedRectangle(cornerRadius: size == .large ? 16 : 10))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: size == .large ? 6 : 3) {
                Text(title.fallback("肩たたき券"))
                    .font(
                        size == .large
                            ? .system(.title3, design: .rounded, weight: .bold)
                            : .system(.subheadline, design: .rounded, weight: .bold)
                    )
                    .foregroundStyle(AppColors.primaryDark)
                    .lineLimit(size == .large ? 2 : 1)
                    .minimumScaleFactor(0.72)

                Text(message.fallback("疲れた時に使ってね。心を込めて肩をたたきます！"))
                    .font(
                        size == .large
                            ? .system(.caption, design: .rounded, weight: .medium)
                            : .system(.caption2, design: .rounded, weight: .medium)
                    )
                    .foregroundStyle(AppColors.textSecondary)
                    .lineLimit(size == .large ? 3 : 2)

                if senderName != nil || date != nil {
                    HStack(spacing: 6) {
                        if let senderName, !senderName.isEmpty {
                            Text("\(senderName)さんから")
                                .lineLimit(1)
                        }
                        if let date {
                            Text(date.formatted(date: .numeric, time: .omitted))
                                .lineLimit(1)
                        }
                    }
                    .font(.system(.caption2, design: .rounded, weight: .semibold))
                    .foregroundStyle(AppColors.textSecondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.leading, size == .large ? 5 : 2)
    }

    private var stub: some View {
        VStack(spacing: size == .large ? 7 : 4) {
            Image(systemName: "pawprint.fill")
                .font(size == .large ? .title3 : .caption)
                .foregroundStyle(AppColors.primary)

            Text("こころ")
                .font(.system(.caption2, design: .rounded, weight: .bold))
                .foregroundStyle(AppColors.primaryDark)
                .rotationEffect(.degrees(90))
                .fixedSize()

            Image(systemName: "heart.fill")
                .font(size == .large ? .caption : .caption2)
                .foregroundStyle(AppColors.pastelPink)
        }
        .padding(.leading, size == .large ? 6 : 3)
    }

    @ViewBuilder
    private var ticketBorder: some View {
        switch design.borderStyle {
        case .simple:
            TicketShape()
                .stroke(AppColors.primary.opacity(0.72), lineWidth: 1.2)
        case .dashed:
            TicketShape()
                .stroke(
                    AppColors.primary.opacity(0.72),
                    style: StrokeStyle(lineWidth: 1.3, dash: [6, 4])
                )
        case .double:
            ZStack {
                TicketShape()
                    .stroke(AppColors.primary.opacity(0.72), lineWidth: 1.2)
                TicketShape(cornerRadius: 16, notchRadius: 8)
                    .stroke(AppColors.primary.opacity(0.52), lineWidth: 1)
                    .padding(4)
            }
        case .roundedBold:
            TicketShape()
                .stroke(AppColors.primary.opacity(0.72), lineWidth: 3)
        }
    }

    private var accessibilityDescription: String {
        [title, message, senderName].compactMap { $0 }.joined(separator: "、")
    }
}

private extension String {
    func fallback(_ value: String) -> String {
        trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? value : self
    }
}

#Preview {
    TicketVisualView(
        title: "肩たたき券",
        message: "疲れた時に使ってね。心を込めて肩をたたきます！",
        illustration: TicketIllustration(id: "cat_happy"),
        design: TicketDesign(backgroundColor: .lightBlue, borderStyle: .double),
        senderName: "こころ",
        date: .now
    )
    .padding()
    .background(AppColors.background)
}
