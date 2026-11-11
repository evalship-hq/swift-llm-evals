// tinyeval worker: evals/support.sh starts it with `worker swift run -q -c release evalworker`.
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import Support
import Tinyeval

let support = Support()  // once per worker, not once per test case
await Tinyeval.worker { input in
    do {
        return try await support.answer(input)
    } catch {
        // When the cause isn't the app (no key, a bad key, a rate limit, a server error, a timeout or the network),
        // tinyeval counts it as couldn't run. Any other error, like a bad model name, is the reply, so the eval fails.
        switch error {
        case Support.Failure.noKey, Support.Failure.api(401, _), Support.Failure.api(429, _),
            Support.Failure.api(500..., _), is URLError:
            throw Tinyeval.CouldntRun(error is URLError ? error.localizedDescription : "\(error)")
        default:
            throw error
        }
    }
}
