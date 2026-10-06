import AppKit
import SwiftUI

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
