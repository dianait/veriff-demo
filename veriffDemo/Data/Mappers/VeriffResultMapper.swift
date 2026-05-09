import Foundation
import Veriff

nonisolated enum VeriffResultMapper {
    static func toDomain(_ result: VeriffSdk.Result) -> VerificationResult {
        switch result.status {
        case .done:
            return .completed
        case .canceled:
            return .cancelled
        case .error(let error):
            return .failed(.unknown(reason: "Veriff SDK error code \(error.rawValue)"))
        @unknown default:
            return .failed(.unknown(reason: "Unknown SDK status"))
        }
    }
}
