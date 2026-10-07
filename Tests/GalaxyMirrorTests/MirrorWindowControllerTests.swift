import CoreGraphics
import Testing
@testable import GalaxyMirror

@MainActor
struct MirrorWindowControllerTests {
    private let screen = CGSize(width: 1296, height: 810)
    private let portrait = CGSize(width: 886, height: 1920)
    private let landscape = CGSize(width: 1920, height: 886)

    @Test func keepsLongSideWhenRotating() {
        let upright = MirrorWindowController.fittedContentSize(for: portrait, longSide: 720, maxSize: screen)
        let rotated = MirrorWindowController.fittedContentSize(for: landscape, longSide: 720, maxSize: screen)

        #expect(upright == CGSize(width: 332, height: 720))
        #expect(rotated == CGSize(width: 720, height: 332))
    }

    @Test func shrinksToFitTheScreen() {
        let size = MirrorWindowController.fittedContentSize(for: landscape, longSide: 1600, maxSize: screen)

        #expect(size.width == 1296)
        #expect(abs(size.width / size.height - landscape.width / landscape.height) < 0.01)
    }
}
