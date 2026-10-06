import SwiftUI

struct MirrorIllustration: View {
    enum Status { case idle, searching, connected }

    var status: Status = .idle

    var body: some View {
        ZStack(alignment: .topLeading) {
            laptop
            if status == .searching {
                PulseRings().frame(width: 200, height: 200).offset(x: 415, y: 29)
            }
            GalaxyPhone(connected: status == .connected).offset(x: 476, y: 46)
        }
        .frame(width: 560, height: 266, alignment: .topLeading)
    }

    private var laptop: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(white: 0.07))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(Color(white: 0.55), lineWidth: 2)
                )
                .frame(width: 400, height: 250)
                .offset(x: 30)

            MacScreen()
                .frame(width: 384, height: 228)
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                .offset(x: 38, y: 10)

            UnevenRoundedRectangle(bottomLeadingRadius: 4, bottomTrailingRadius: 4)
                .fill(Color(white: 0.07))
                .frame(width: 44, height: 8)
                .offset(x: 208, y: 10)

            UnevenRoundedRectangle(
                topLeadingRadius: 2, bottomLeadingRadius: 12,
                bottomTrailingRadius: 12, topTrailingRadius: 2
            )
            .fill(LinearGradient(colors: [Color(white: 0.66), Color(white: 0.46)], startPoint: .top, endPoint: .bottom))
            .frame(width: 460, height: 16)
            .offset(y: 246)

            UnevenRoundedRectangle(bottomLeadingRadius: 6, bottomTrailingRadius: 6)
                .fill(Color(white: 0.4))
                .frame(width: 80, height: 5)
                .offset(x: 190, y: 246)
        }
    }
}

private struct MacScreen: View {
    var body: some View {
        ZStack(alignment: .topLeading) {
            LinearGradient(
                colors: [
                    Color(red: 0.28, green: 0.25, blue: 0.58),
                    Color(red: 0.43, green: 0.27, blue: 0.53),
                    Color(red: 0.6, green: 0.38, blue: 0.62),
                ],
                startPoint: .top, endPoint: .bottom
            )

            HStack(spacing: 5) {
                ForEach([10, 8, 12, 8, 6, 14], id: \.self) { Capsule().frame(width: CGFloat($0), height: 3) }
                Spacer()
                ForEach([8, 4, 4, 6, 10], id: \.self) { Capsule().frame(width: CGFloat($0), height: 3) }
            }
            .foregroundStyle(.white.opacity(0.55))
            .padding(.horizontal, 8)
            .frame(width: 384)
            .offset(y: 5)

            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(.black.opacity(0.16))
                .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(.white.opacity(0.06)))
                .frame(width: 170, height: 108)
                .offset(x: 72, y: 52)

            MiniOneUI()
                .frame(width: 78, height: 158)
                .background(Color(white: 0.08), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(.white.opacity(0.18)))
                .shadow(color: .black.opacity(0.35), radius: 8, y: 4)
                .offset(x: 226, y: 28)

            Image(systemName: "cursorarrow")
                .font(.system(size: 13))
                .foregroundStyle(.white)
                .shadow(radius: 1)
                .offset(x: 284, y: 112)

            Dock().offset(x: 82, y: 196)
        }
    }
}

private struct MiniOneUI: View {
    private let avatars: [Color] = [.green, .blue, .orange, .pink, .teal]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Circle().fill(.black).frame(width: 4, height: 4).frame(maxWidth: .infinity)
            Capsule().fill(.white.opacity(0.75)).frame(width: 36, height: 5)
            Capsule().fill(Color.accentColor.opacity(0.9)).frame(width: 60, height: 7)
            ForEach(avatars.indices, id: \.self) { i in
                HStack(spacing: 4) {
                    Circle().fill(avatars[i].opacity(0.8)).frame(width: 9, height: 9)
                    VStack(alignment: .leading, spacing: 2) {
                        Capsule().fill(.white.opacity(0.55)).frame(width: 30, height: 3)
                        Capsule().fill(.white.opacity(0.25)).frame(width: 44, height: 3)
                    }
                }
            }
            Spacer(minLength: 0)
            HStack(spacing: 12) {
                Image(systemName: "line.3.horizontal").font(.system(size: 5))
                RoundedRectangle(cornerRadius: 1).stroke(lineWidth: 0.8).frame(width: 5, height: 5)
                Image(systemName: "chevron.left").font(.system(size: 5))
            }
            .foregroundStyle(.white.opacity(0.6))
            .frame(maxWidth: .infinity)
        }
        .padding(7)
    }
}

private struct Dock: View {
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<10) { i in
                if i == 6 {
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(LinearGradient(colors: [.cyan, .blue], startPoint: .top, endPoint: .bottom))
                        .overlay(
                            Image(systemName: "iphone.gen3")
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundStyle(.white)
                        )
                        .frame(width: 16, height: 16)
                } else {
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(.white.opacity(0.3))
                        .frame(width: 16, height: 16)
                }
            }
        }
        .padding(4)
        .background(.white.opacity(0.2), in: RoundedRectangle(cornerRadius: 7, style: .continuous))
    }
}

private struct PulseRings: View {
    @State private var animate = false

    var body: some View {
        ZStack {
            ForEach(0..<3) { i in
                Circle()
                    .stroke(Color.accentColor.opacity(0.6), lineWidth: 1.5)
                    .scaleEffect(animate ? 1.0 : 0.35)
                    .opacity(animate ? 0 : 0.9)
                    .animation(
                        .easeOut(duration: 2.4).repeatForever(autoreverses: false).delay(Double(i) * 0.8),
                        value: animate
                    )
            }
        }
        .onAppear { animate = true }
    }
}
