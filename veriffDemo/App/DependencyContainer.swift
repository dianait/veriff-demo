import Foundation

@MainActor
final class DependencyContainer {
    private let demoSessionURL = "https://alchemy.veriff.com/v/eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpYXQiOjE3NzgzNTUyMTIsInNlc3Npb25faWQiOiJlMzZmYTMyNi1mZGJkLTQ2ODYtOGJhOS0zODFmN2JkMzdmNDUiLCJpaWQiOiIzMDlkMThjYS1iNWNkLTRkODAtYWJjYS04YTE1YTNhODEzOTciLCJ2aWQiOiI4ZmM0NjI3MS0yYmY3LTQwYWQtOWU4My1lMzkyYjI0YWNjMDQiLCJjaWQiOiJzYWFzLTQiLCJleHAiOjE3Nzg5NjAwMTJ9.Wz0z-6eMUhzEfgRphxNoVrK9lIaU3yZ40B7UtIKu44s"

    private lazy var sessionRepository: SessionRepositoryProtocol = SessionRepository(demoSessionURL: demoSessionURL)
    private lazy var verificationService: VerificationServiceProtocol = VeriffVerificationService()

    private lazy var createSessionUseCase: CreateVerificationSessionUseCaseProtocol = CreateVerificationSessionUseCase(repository: sessionRepository)
    private lazy var startVerificationUseCase: StartVerificationUseCaseProtocol = StartVerificationUseCase(service: verificationService)

    func makeVerificationViewModel() -> VerificationViewModel {
        VerificationViewModel(
            createSessionUseCase: createSessionUseCase,
            startVerificationUseCase: startVerificationUseCase
        )
    }
}
