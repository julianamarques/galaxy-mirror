import Foundation

struct ServerConnection: @unchecked Sendable {
    let video: TCPSocket
    let audio: TCPSocket?
    let control: TCPSocket
    let process: Process
    let log: ServerLog

    func close() {
        video.close()
        audio?.close()
        control.close()
        Tools.terminate(process, after: 1)
    }
}
