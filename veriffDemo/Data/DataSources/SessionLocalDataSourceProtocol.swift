import Foundation

nonisolated protocol SessionLocalDataSourceProtocol: Sendable {
    func load() -> VerificationSession?
    func save(_ session: VerificationSession)
    func clear()
}
