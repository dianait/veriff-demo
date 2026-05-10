import Foundation

enum VerificationState: Equatable {
    case idle
    case loading
    case completed
    case cancelled
    case failed(String)
}

extension VerificationResult {
    var state: VerificationState {
        switch self {
        case .completed: return .completed
        case .cancelled: return .cancelled
        case .failed(let error): return .failed(error.message)
        }
    }
}
