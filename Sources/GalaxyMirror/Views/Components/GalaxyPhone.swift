import SwiftUI

struct GalaxyPhone: View {
    var connected = false

    var body: some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .fill(Color(white: 0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                        .strokeBorder(Color(white: 0.5), lineWidth: 1.5)
                )

            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.12, green: 0.2, blue: 0.45),
                            Color(red: 0.3, green: 0.42, blue: 0.75),
                            Color(red: 0.62, green: 0.55, blue: 0.85),
                        ],
                        startPoint: .top, endPoint: .bottom
                    )
                )
                .padding(3)

            VStack(spacing: 1) {
                Circle().fill(.black).frame(width: 5, height: 5).padding(.top, 8)
                Text(verbatim: "9:41")
                    .font(.system(size: 22, weight: .light, design: .rounded))
                    .foregroundStyle(.white.opacity(0.92))
                    .padding(.top, 12)
                Text("seg., 6 de out.")
                    .font(.system(size: 6, weight: .medium))
                    .foregroundStyle(.white.opacity(0.7))
                Spacer()
                if connected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(.white, .green)
                        .padding(.bottom, 14)
                        .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .overlay(alignment: .trailing) {
            VStack(spacing: 4) {
                Capsule().frame(width: 2, height: 18)
                Capsule().frame(width: 2, height: 10)
            }
            .foregroundStyle(Color(white: 0.45))
            .offset(x: 2, y: -30)
        }
        .frame(width: 80, height: 168)
        .animation(.spring(duration: 0.4), value: connected)
    }
}
