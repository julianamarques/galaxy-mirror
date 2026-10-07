import AppKit
import SwiftUI

struct AndroidRobot: View {
    var color = Color(red: 0.24, green: 0.86, blue: 0.52)
    var eyeColor: Color

    var body: some View {
        ZStack(alignment: .topLeading) {
            Capsule().fill(color).frame(width: 22, height: 44).offset(x: 49, y: 136)
            Capsule().fill(color).frame(width: 22, height: 44).offset(x: 83, y: 136)
            Capsule().fill(color).frame(width: 22, height: 64).offset(x: 0, y: 78)
            Capsule().fill(color).frame(width: 22, height: 64).offset(x: 132, y: 78)
            UnevenRoundedRectangle(bottomLeadingRadius: 14, bottomTrailingRadius: 14)
                .fill(color)
                .frame(width: 100, height: 82)
                .offset(x: 27, y: 74)
            Path { path in
                path.addArc(center: CGPoint(x: 77, y: 70), radius: 50, startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
                path.closeSubpath()
            }
            .fill(color)
            Path { path in
                for angle in [235.0, 305.0] {
                    let radians = angle * .pi / 180
                    path.move(to: CGPoint(x: 77 + 40 * cos(radians), y: 70 + 40 * sin(radians)))
                    path.addLine(to: CGPoint(x: 77 + 64 * cos(radians), y: 70 + 64 * sin(radians)))
                }
            }
            .stroke(color, style: StrokeStyle(lineWidth: 6, lineCap: .round))
            ForEach([57.0, 97.0], id: \.self) { x in
                Circle().fill(eyeColor).frame(width: 10, height: 10).position(x: x, y: 50)
            }
        }
        .frame(width: 154, height: 180, alignment: .topLeading)
    }
}

struct Icon: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 230, style: .continuous)
                .fill(LinearGradient(colors: [Color(red: 0.36, green: 0.55, blue: 1), Color(red: 0.12, green: 0.26, blue: 0.85)],
                                     startPoint: .top, endPoint: .bottom))
                .frame(width: 824, height: 824)
            RoundedRectangle(cornerRadius: 70, style: .continuous)
                .fill(.white.opacity(0.22))
                .frame(width: 520, height: 360)
                .offset(x: -70, y: 40)
            RoundedRectangle(cornerRadius: 60, style: .continuous)
                .fill(.white)
                .frame(width: 250, height: 500)
                .overlay(
                    RoundedRectangle(cornerRadius: 46, style: .continuous)
                        .fill(LinearGradient(colors: [Color(red: 0.15, green: 0.22, blue: 0.5), Color(red: 0.5, green: 0.45, blue: 0.85)],
                                             startPoint: .top, endPoint: .bottom))
                        .padding(14)
                )
                .overlay(alignment: .top) { Circle().fill(.black).frame(width: 22).padding(.top, 34) }
                .overlay {
                    AndroidRobot(eyeColor: Color(red: 0.3, green: 0.32, blue: 0.66))
                        .scaleEffect(1.05)
                        .offset(y: 18)
                }
                .shadow(color: .black.opacity(0.3), radius: 24, y: 12)
                .offset(x: 150, y: -10)
        }
        .frame(width: 1024, height: 1024)
    }
}

let iconset = URL(fileURLWithPath: "build/AppIcon.iconset")
try? FileManager.default.removeItem(at: iconset)
try FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)

MainActor.assumeIsolated {
    var rendered: [Int: Data] = [:]
    for size in [16, 32, 128, 256, 512] {
        for scale in [1, 2] {
            let pixels = size * scale
            if rendered[pixels] == nil {
                let renderer = ImageRenderer(content: Icon())
                renderer.scale = CGFloat(pixels) / 1024
                guard let image = renderer.cgImage else { fatalError("render failed") }
                rendered[pixels] = NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:])!
            }
            let name = scale == 1 ? "icon_\(size)x\(size).png" : "icon_\(size)x\(size)@2x.png"
            try! rendered[pixels]!.write(to: iconset.appendingPathComponent(name))
        }
    }
}

let task = Process()
task.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
task.arguments = ["-c", "icns", iconset.path, "-o", "Resources/AppIcon.icns"]
try task.run()
task.waitUntilExit()
print("Resources/AppIcon.icns")
