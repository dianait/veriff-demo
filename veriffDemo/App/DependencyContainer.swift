import Foundation

@MainActor
final class DependencyContainer {
    private lazy var sessionRepository: SessionRepositoryProtocol = makeSessionRepository()
    private lazy var verificationService: VerificationServiceProtocol = VeriffVerificationService()

    private lazy var createSessionUseCase: CreateVerificationSessionUseCaseProtocol = CreateVerificationSessionUseCase(repository: sessionRepository)
    private lazy var startVerificationUseCase: StartVerificationUseCaseProtocol = StartVerificationUseCase(service: verificationService)

    func makeVerificationViewModel() -> VerificationViewModel {
        VerificationViewModel(
            createSessionUseCase: createSessionUseCase,
            startVerificationUseCase: startVerificationUseCase
        )
    }

    // The app always creates a fresh session via Veriff's POST /v1/sessions.
    // If Secrets.plist is missing or its API key is empty, return a repository that
    // throws a clear `.missingConfiguration` so the failure surfaces in the UI
    // instead of crashing on launch.
    private func makeSessionRepository() -> SessionRepositoryProtocol {
        guard let config = VeriffAPIConfig.loadFromBundle() else {
            return UnconfiguredSessionRepository()
        }
        return HTTPSessionRepository(config: config)
    }
}

private struct UnconfiguredSessionRepository: SessionRepositoryProtocol {
    func createSession() async throws -> VerificationSession {
        throw VerificationError.missingConfiguration
    }
}
