import Foundation

enum VerificationState: Equatable {
    case idle
    case loading
    case completed
    case cancelled
    case failed(String)
}
