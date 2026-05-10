import Foundation

nonisolated enum VerificationError: Error, Equatable {
    case missingConfiguration
    case invalidSession
    case network
    case unknown(reason: String)
}
