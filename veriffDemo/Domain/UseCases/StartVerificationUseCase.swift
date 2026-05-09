import Foundation

@MainActor
protocol StartVerificationUseCaseProtocol {
    func execute(session: VerificationSession) async -> VerificationResult
}

final class StartVerificationUseCase: StartVerificationUseCaseProtocol {
    private let service: VerificationServiceProtocol

    init(service: VerificationServiceProtocol) {
        self.service = service
    }

    func execute(session: VerificationSession) async -> VerificationResult {
        await service.start(session: session)
    }
}
