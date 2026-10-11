import CoreMedia
import Foundation

final class VideoSampleBuilder {
    enum BuildError: LocalizedError {
        case missingParameterSets

        var errorDescription: String? { String(localized: "O Galaxy não enviou a configuração do vídeo.") }
    }

    let codec: Codec
    private(set) var format: CMVideoFormatDescription?

    init(codec: Codec) {
        self.codec = codec
    }

    func applyConfig(_ data: [UInt8]) throws {
        let parameterSets = Self.nalUnits(in: data).filter { isParameterSet(data[$0.lowerBound]) }
        guard !parameterSets.isEmpty else { throw BuildError.missingParameterSets }
        try updateFormat(parameterSets.map { Data(data[$0]) })
    }

    func sampleBuffer(_ data: [UInt8], pts: UInt64, isKeyFrame: Bool) throws -> CMSampleBuffer? {
        var frames: [Range<Int>] = []
        var parameterSets: [Data] = []
        for unit in Self.nalUnits(in: data) {
            if isParameterSet(data[unit.lowerBound]) {
                parameterSets.append(Data(data[unit]))
            } else {
                frames.append(unit)
            }
        }
        if !parameterSets.isEmpty {
            try updateFormat(parameterSets)
        }
        guard let format, !frames.isEmpty else { return nil }

        let length = frames.reduce(0) { $0 + $1.count + 4 }
        let block = try CMBlockBuffer(length: length, flags: .assureMemoryNow)
        try block.withUnsafeMutableBytes { output in
            data.withUnsafeBytes { input in
                var offset = 0
                for frame in frames {
                    output.storeBytes(of: UInt32(frame.count).bigEndian, toByteOffset: offset, as: UInt32.self)
                    UnsafeMutableRawBufferPointer(rebasing: output[(offset + 4)...])
                        .copyMemory(from: UnsafeRawBufferPointer(rebasing: input[frame]))
                    offset += frame.count + 4
                }
            }
        }

        let timing = CMSampleTimingInfo(
            duration: .invalid,
            presentationTimeStamp: CMTime(value: CMTimeValue(pts), timescale: 1_000_000),
            decodeTimeStamp: .invalid
        )
        let sample = try CMSampleBuffer(
            dataBuffer: block, formatDescription: format, numSamples: 1,
            sampleTimings: [timing], sampleSizes: [length]
        )
        sample.sampleAttachments[0][.displayImmediately] = true
        if !isKeyFrame {
            sample.sampleAttachments[0][.notSync] = true
        }
        return sample
    }

    static func nalUnits(in data: [UInt8]) -> [Range<Int>] {
        data.withUnsafeBufferPointer { bytes in
            var starts: [(payload: Int, prefix: Int)] = []
            var index = 2
            while index < bytes.count {
                if bytes[index] == 1, bytes[index - 1] == 0, bytes[index - 2] == 0 {
                    let prefix = index >= 3 && bytes[index - 3] == 0 ? index - 3 : index - 2
                    starts.append((index + 1, prefix))
                    index += 3
                } else {
                    index += bytes[index] > 1 ? 3 : 1
                }
            }
            return starts.indices.compactMap { position in
                let end = position + 1 < starts.count ? starts[position + 1].prefix : bytes.count
                let start = starts[position].payload
                return end > start ? start..<end : nil
            }
        }
    }

    func isParameterSet(_ header: UInt8) -> Bool {
        switch codec {
        case .h264:
            switch header & 0x1F {
            case 7, 8: true
            default: false
            }
        case .h265:
            switch (header >> 1) & 0x3F {
            case 32...34: true
            default: false
            }
        }
    }

    private func updateFormat(_ parameterSets: [Data]) throws {
        switch codec {
        case .h264:
            format = try CMVideoFormatDescription(h264ParameterSets: parameterSets, nalUnitHeaderLength: 4)
        case .h265:
            format = try CMVideoFormatDescription(hevcParameterSets: parameterSets, nalUnitHeaderLength: 4)
        }
    }
}
