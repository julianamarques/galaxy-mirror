import Foundation
import Testing

struct LocalizationTests {
    private struct Catalog: Decodable {
        struct Entry: Decodable {
            struct Localization: Decodable {
                struct Unit: Decodable {
                    let state: String
                    let value: String
                }
                let stringUnit: Unit?
            }
            let localizations: [String: Localization]?
        }
        let sourceLanguage: String
        let strings: [String: Entry]
    }

    private static let catalogs = ["Localizable", "InfoPlist"]

    private func catalog(_ name: String) throws -> Catalog {
        let url = URL(filePath: FileManager.default.currentDirectoryPath).appending(path: "Resources/\(name).xcstrings")
        return try JSONDecoder().decode(Catalog.self, from: Data(contentsOf: url))
    }

    private func placeholders(_ text: String) -> [String] {
        text.matches(of: /%(?:\d+\$)?(?:lld|ld|d|@|f|x)/).map { String($0.output) }
    }

    @Test(arguments: catalogs) func sourceIsPortuguese(name: String) throws {
        #expect(try catalog(name).sourceLanguage == "pt-BR")
    }

    @Test(arguments: catalogs) func everyStringHasAnEnglishTranslation(name: String) throws {
        let missing = try catalog(name).strings.filter { $0.value.localizations?["en"]?.stringUnit?.state != "translated" }
        #expect(missing.isEmpty, "Sem tradução para inglês: \(missing.keys.sorted())")
    }

    @Test func translationsKeepThePlaceholders() throws {
        for (key, entry) in try catalog("Localizable").strings {
            let value = entry.localizations?["en"]?.stringUnit?.value ?? key
            #expect(placeholders(value) == placeholders(key), "Marcadores diferentes em: \(key)")
        }
    }
}
