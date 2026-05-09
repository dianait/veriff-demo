import Foundation

nonisolated enum VerificationResult: Equatable {
    case completed
    case cancelled
    case failed(VerificationError)
}
