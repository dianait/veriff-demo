import Foundation

protocol VerificationProviderProtocol: Sendable {
    func verify() async -> VerificationResult
    func invalidateSession() async
}
