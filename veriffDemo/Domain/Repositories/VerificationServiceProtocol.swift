import Foundation

@MainActor
protocol VerificationServiceProtocol {
    func start(session: VerificationSession) async -> VerificationResult
}
