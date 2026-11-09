// tinyeval worker: evals/support.sh starts it with `worker swift run -q -c release evalworker`.
// It reads each input up to a NUL byte on stdin, and prints the reply and a NUL byte.
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import Support

/// Turns an error into a reply. When the cause isn't the app (no key, a bad key, a rate limit,
/// a server error, a timeout or the network), tinyeval counts it as couldn't run.
/// Any other error, like a bad model name, is the reply, so the eval fails.
func failure(_ error: Error) -> String {
    switch error {
    case Support.Failure.noKey, Support.Failure.api(401, _), Support.Failure.api(429, _),
        Support.Failure.api(500..., _), is URLError:
        let reason = error is URLError ? error.localizedDescription : "\(error)"
        return "#tinyeval couldnt_run \(reason.replacingOccurrences(of: "\n", with: " "))\n"
    default:
        return "error: \(error)"
    }
}

let support = Support()  // once per worker, not once per test case
var rest: [UInt8] = []
while true {
    let chunk = FileHandle.standardInput.availableData
    if chunk.isEmpty { break }
    rest += chunk
    while let end = rest.firstIndex(of: 0) {
        let input = String(decoding: rest[..<end], as: UTF8.self)
        rest.removeSubrange(...end)
        let reply: String
        do {
            reply = try await support.answer(input)
        } catch {
            reply = failure(error)
        }
        FileHandle.standardOutput.write(Data((reply + "\0").utf8))
    }
}
