import Foundation

nonisolated final class SessionRepository: SessionRepositoryProtocol {
    private let remote: SessionRemoteDataSourceProtocol
    private let local: SessionLocalDataSourceProtocol
    private let maxAge: TimeInterval

    init(
        remote: SessionRemoteDataSourceProtocol,
        local: SessionLocalDataSourceProtocol,
        maxAge: TimeInterval = VerificationSession.maxLifetime
    ) {
        self.remote = remote
        self.local = local
        self.maxAge = maxAge
    }

    func getSession() async throws -> VerificationSession {
        if let cached = local.load(), !cached.isExpired(maxAge: maxAge) {
            return cached
        }
        local.clear()
        let fresh = try await remote.createSession()
        local.save(fresh)
        return fresh
    }

    func invalidate() async {
        local.clear()
    }
}
