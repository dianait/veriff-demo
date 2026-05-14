import Foundation

nonisolated protocol SessionRepositoryProtocol: Sendable {
    func getSession() async throws -> VerificationSession
    func invalidate() async
}
