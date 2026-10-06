// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "GalaxyMirror",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "GalaxyMirror",
            path: "Sources/GalaxyMirror"
        ),
        .testTarget(
            name: "GalaxyMirrorTests",
            dependencies: ["GalaxyMirror"]
        ),
    ]
)
