import Foundation

enum VerificationResult: Equatable {
    case completed
    case cancelled
    case failed(VerificationError)
}
