import Foundation

nonisolated protocol CreateVerificationSessionUseCaseProtocol: Sendable {
    func execute() async throws -> VerificationSession
}

nonisolated final class CreateVerificationSessionUseCase: CreateVerificationSessionUseCaseProtocol {
    private let repository: SessionRepositoryProtocol

    init(repository: SessionRepositoryProtocol) {
        self.repository = repository
    }

    func execute() async throws -> VerificationSession {
        try await repository.createSession()
    }
}
