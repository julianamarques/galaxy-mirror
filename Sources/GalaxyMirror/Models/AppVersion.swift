import Foundation

struct AppVersion: Comparable, CustomStringConvertible {
    let major: Int
    let minor: Int
    let patch: Int
    let stage: String?
    let stageNumber: Int

    var isPrerelease: Bool { stage != nil }

    var description: String {
        let base = "\(major).\(minor).\(patch)"
        guard let stage else { return base }
        return "\(base)-\(stage).\(stageNumber)"
    }

    init?(_ text: String) {
        let trimmed = text.hasPrefix("v") ? String(text.dropFirst()) : text
        let parts = trimmed.split(separator: "-", maxSplits: 1).map(String.init)
        guard let base = parts.first else { return nil }
        let numbers = base.split(separator: ".").compactMap { Int($0) }
        guard numbers.count == 3, base.split(separator: ".").count == 3 else { return nil }
        major = numbers[0]
        minor = numbers[1]
        patch = numbers[2]

        guard parts.count == 2 else {
            stage = nil
            stageNumber = 0
            return
        }
        let suffix = parts[1].split(separator: ".").map(String.init)
        guard suffix.count == 2, ["alpha", "beta", "rc"].contains(suffix[0]), let number = Int(suffix[1]) else {
            return nil
        }
        stage = suffix[0]
        stageNumber = number
    }

    static func < (lhs: AppVersion, rhs: AppVersion) -> Bool {
        if (lhs.major, lhs.minor, lhs.patch) != (rhs.major, rhs.minor, rhs.patch) {
            return (lhs.major, lhs.minor, lhs.patch) < (rhs.major, rhs.minor, rhs.patch)
        }
        return (lhs.stageRank, lhs.stageNumber) < (rhs.stageRank, rhs.stageNumber)
    }

    private var stageRank: Int {
        switch stage {
        case "alpha": 0
        case "beta": 1
        case "rc": 2
        default: 3
        }
    }

    static var current: AppVersion? {
        let info = Bundle.main.infoDictionary
        let text = info?["GalaxyMirrorReleaseVersion"] as? String ?? info?["CFBundleShortVersionString"] as? String
        return text.flatMap(AppVersion.init)
    }
}
