import CoreGraphics
import Testing
@testable import GalaxyMirror

struct MirrorViewTests {
    private let video = CGSize(width: 1080, height: 2340)

    @Test func mapsPointsInsideTheVideo() {
        let position = MirrorView.devicePosition(of: CGPoint(x: 270, y: 585), in: CGSize(width: 540, height: 1170), videoSize: video)

        #expect(position == ControlMessage.Position(x: 540, y: 1170, screenWidth: 1080, screenHeight: 2340))
    }

    @Test func accountsForLetterboxing() {
        let position = MirrorView.devicePosition(of: CGPoint(x: 100, y: 0), in: CGSize(width: 740, height: 1170), videoSize: video)

        #expect(position?.x == 0)
        #expect(position?.y == 0)
    }

    @Test func requiresKnownVideoSize() {
        #expect(MirrorView.devicePosition(of: .zero, in: CGSize(width: 10, height: 10), videoSize: .zero) == nil)
    }
}
