import Foundation
import Testing
@testable import GalaxyMirror

struct UpdateCheckerTests {
    private let json = #"""
    [
      {"tag_name": "v0.2.0-beta.1", "html_url": "https://github.com/x/y/releases/tag/v0.2.0-beta.1", "body": "## Installation\n\nDownload.\n\n- not a change\n\n## Changes\n\n- fix: one\n- feat: two\n", "draft": false, "prerelease": true,
       "assets": [{"name": "Galaxy-Mirror.dmg", "browser_download_url": "https://github.com/x/y/releases/download/v0.2.0-beta.1/Galaxy-Mirror.dmg"}]},
      {"tag_name": "v0.3.0", "html_url": "https://github.com/x/y/releases/tag/v0.3.0", "body": null, "draft": true, "prerelease": false, "assets": []},
      {"tag_name": "v0.1.6", "html_url": "https://github.com/x/y/releases/tag/v0.1.6", "body": "", "draft": false, "prerelease": false, "assets": []},
      {"tag_name": "v0.1.5-beta.1", "html_url": "https://github.com/x/y/releases/tag/v0.1.5-beta.1", "body": "", "draft": false, "prerelease": true, "assets": []}
    ]
    """#

    private func releases() throws -> [AppRelease] {
        try JSONDecoder().decode([AppRelease].self, from: Data(json.utf8))
    }

    @Test func offersNewestPrereleaseToBetaUsers() throws {
        let release = UpdateChecker.newestRelease(in: try releases(), newerThan: try #require(AppVersion("0.1.5-beta.1")))

        #expect(release?.tagName == "v0.2.0-beta.1")
        #expect(release?.downloadURL.lastPathComponent == "Galaxy-Mirror.dmg")
    }

    @Test func offersOnlyStableReleasesToStableUsers() throws {
        let release = UpdateChecker.newestRelease(in: try releases(), newerThan: try #require(AppVersion("0.1.5")))

        #expect(release?.tagName == "v0.1.6")
        #expect(release?.downloadURL.absoluteString == "https://github.com/x/y/releases/tag/v0.1.6")
    }

    @Test func ignoresDraftsAndReportsUpToDate() throws {
        #expect(UpdateChecker.newestRelease(in: try releases(), newerThan: try #require(AppVersion("0.2.0-beta.1"))) == nil)
    }

    @Test func summarizesTheChangesSection() throws {
        #expect(UpdateChecker.summary(of: try releases()[0].body) == ["fix: one", "feat: two"])
        #expect(UpdateChecker.summary(of: nil).isEmpty)
    }

    @Test func summarizesOlderPortugueseNotes() {
        let notes = "## Instalação\n\nBaixe.\n\n## Mudanças\n\n- fix: one\n"

        #expect(UpdateChecker.summary(of: notes) == ["fix: one"])
    }
}
