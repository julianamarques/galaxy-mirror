import AppKit
import CoreImage.CIFilterBuiltins
import SwiftUI

struct QRCodeView: View {
    let payload: String
    @State private var image: NSImage?

    var body: some View {
        Image(nsImage: image ?? NSImage())
            .interpolation(.none)
            .resizable()
            .scaledToFit()
            .task(id: payload) { image = Self.render(payload) }
    }

    private static func render(_ payload: String) -> NSImage? {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(payload.utf8)
        filter.correctionLevel = "M"
        guard let output = filter.outputImage?.transformed(by: CGAffineTransform(scaleX: 12, y: 12)),
              let cgImage = CIContext().createCGImage(output, from: output.extent)
        else { return nil }
        return NSImage(cgImage: cgImage, size: output.extent.size)
    }
}
