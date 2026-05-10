import Foundation

protocol VerificationServiceProtocol: Sendable {
    func start(session: VerificationSession) async -> VerificationResult
}
