import Foundation

let args = CommandLine.arguments
guard args.count == 3 else {
    FileHandle.standardError.write(Data("uso: make-source-strings.swift <catálogo.xcstrings> <pasta de saída>\n".utf8))
    exit(1)
}
let catalogURL = URL(fileURLWithPath: args[1])
let catalog = try JSONSerialization.jsonObject(with: Data(contentsOf: catalogURL)) as! [String: Any]
let language = catalog["sourceLanguage"] as! String
let strings = catalog["strings"] as! [String: Any]
let table = Dictionary(uniqueKeysWithValues: strings.map { key, entry in
    let localizations = (entry as? [String: Any])?["localizations"] as? [String: Any]
    let unit = (localizations?[language] as? [String: Any])?["stringUnit"] as? [String: Any]
    return (key, unit?["value"] as? String ?? key)
})

let name = catalogURL.deletingPathExtension().lastPathComponent
let folder = URL(fileURLWithPath: args[2]).appendingPathComponent("\(language).lproj")
try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
try PropertyListSerialization.data(fromPropertyList: table, format: .xml, options: 0)
    .write(to: folder.appendingPathComponent("\(name).strings"))
print("Pronto: \(folder.path)/\(name).strings (\(table.count) textos)")
