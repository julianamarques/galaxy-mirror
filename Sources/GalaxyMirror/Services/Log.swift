import OSLog

enum Log {
    static let subsystem = "com.julianamarques.GalaxyMirror"
    static let adb = Logger(subsystem: subsystem, category: "adb")
    static let mirror = Logger(subsystem: subsystem, category: "mirror")
    static let updates = Logger(subsystem: subsystem, category: "updates")
}
