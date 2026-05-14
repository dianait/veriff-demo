import Foundation

nonisolated protocol SessionRemoteDataSourceProtocol: Sendable {
    func createSession() async throws -> VerificationSession
}
