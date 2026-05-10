import Foundation

nonisolated protocol SessionRepositoryProtocol: Sendable {
    func createSession() async throws -> VerificationSession
}
