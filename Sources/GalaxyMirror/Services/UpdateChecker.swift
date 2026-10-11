import Foundation

enum UpdateChecker {
    static let releasesURL = URL(string: "https://api.github.com/repos/julianamarques/galaxy-mirror/releases?per_page=20")!

    static func fetchReleases() async throws -> [AppRelease] {
        var request = URLRequest(url: releasesURL, timeoutInterval: 15)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("GalaxyMirror", forHTTPHeaderField: "User-Agent")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw ToolError.failed(String(localized: "Não foi possível consultar as atualizações no GitHub."))
        }
        return try JSONDecoder().decode([AppRelease].self, from: data)
    }

    private static let changesHeadings: Set<String> = ["changes", "mudanças"]

    static func summary(of notes: String?, limit: Int = 8) -> [String] {
        guard let notes else { return [] }
        var inChanges = false
        var items: [String] = []
        for line in notes.split(whereSeparator: \.isNewline).map({ $0.trimmingCharacters(in: .whitespaces) }) {
            if line.hasPrefix("## ") {
                inChanges = changesHeadings.contains(line.dropFirst(3).trimmingCharacters(in: .whitespaces).lowercased())
            } else if inChanges, line.hasPrefix("- ") {
                items.append(String(line.dropFirst(2)))
            }
        }
        return Array(items.prefix(limit))
    }

    static func newestRelease(in releases: [AppRelease], newerThan current: AppVersion) -> AppRelease? {
        releases
            .filter { !$0.draft && (current.isPrerelease || !$0.prerelease) }
            .compactMap { release in release.version.map { (release, $0) } }
            .filter { $0.1 > current }
            .max { $0.1 < $1.1 }?
            .0
    }
}
