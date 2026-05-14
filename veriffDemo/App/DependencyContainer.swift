import Foundation

@MainActor
final class DependencyContainer {
    private lazy var sessionRepository: SessionRepositoryProtocol = makeSessionRepository()
    private lazy var verificationProvider: VerificationProviderProtocol = VeriffVerificationProvider(sessionRepository: sessionRepository)

    func makeVerificationViewModel() -> VerificationViewModel {
        VerificationViewModel(verificationProvider: verificationProvider)
    }

    // Coordinator: HTTP remote + Keychain local. Sessions are cached for up to
    // 7 days (Veriff's contract); the provider invalidates on terminal failures.
    // If Secrets.plist is missing or its API key is empty, we return a repository
    // that surfaces .missingConfiguration in the UI instead of crashing on launch.
    private func makeSessionRepository() -> SessionRepositoryProtocol {
        guard let config = VeriffAPIConfig.loadFromBundle() else {
            return UnconfiguredSessionRepository()
        }
        return SessionRepository(
            remote: HTTPSessionRemoteDataSource(config: config),
            local: KeychainSessionLocalDataSource()
        )
    }
}

private struct UnconfiguredSessionRepository: SessionRepositoryProtocol {
    nonisolated func getSession() async throws -> VerificationSession {
        throw VerificationError.missingConfiguration
    }
    nonisolated func invalidate() async {}
}
