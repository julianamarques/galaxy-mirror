import Testing
@testable import GalaxyMirror

struct AppVersionTests {
    @Test func parsesStableAndPrereleaseVersions() throws {
        let stable = try #require(AppVersion("1.2.3"))
        let beta = try #require(AppVersion("v0.1.5-beta.1"))

        #expect(stable.description == "1.2.3")
        #expect(!stable.isPrerelease)
        #expect(beta.description == "0.1.5-beta.1")
        #expect(beta.isPrerelease)
    }

    @Test(arguments: ["1.2", "1.2.3.4", "1.2.x", "1.2.3-gamma.1", "1.2.3-beta", ""])
    func rejectsInvalidVersions(text: String) {
        #expect(AppVersion(text) == nil)
    }

    @Test func ordersVersions() throws {
        let ordered = try ["0.1.4", "0.1.5-alpha.1", "0.1.5-beta.1", "0.1.5-beta.2", "0.1.5-rc.1", "0.1.5", "0.2.0-beta.1", "1.0.0"]
            .map { try #require(AppVersion($0)) }

        #expect(ordered == ordered.sorted())
        #expect(try #require(AppVersion("0.1.10")) > #require(AppVersion("0.1.9")))
    }
}
