import Foundation
import Observation

@MainActor
@Observable
final class VerificationViewModel {
    private(set) var state: VerificationState = .idle

    private let createSessionUseCase: CreateVerificationSessionUseCaseProtocol
    private let startVerificationUseCase: StartVerificationUseCaseProtocol

    init(
        createSessionUseCase: CreateVerificationSessionUseCaseProtocol,
        startVerificationUseCase: StartVerificationUseCaseProtocol
    ) {
        self.createSessionUseCase = createSessionUseCase
        self.startVerificationUseCase = startVerificationUseCase
    }

    func startVerification() async {
        state = .loading
        do {
            let session = try await createSessionUseCase.execute()
            let result = await startVerificationUseCase.execute(session: session)
            state = map(result)
        } catch {
            state = .failed(message(for: error))
        }
    }

    private func map(_ result: VerificationResult) -> VerificationState {
        switch result {
        case .completed: return .completed
        case .cancelled: return .cancelled
        case .failed(let error): return .failed(message(for: error))
        }
    }

    private func message(for error: Error) -> String {
        guard let domain = error as? VerificationError else {
            return "Unexpected error"
        }
        switch domain {
        case .invalidSession: return "Invalid verification session"
        case .network: return "Network error"
        case .cameraUnauthorized: return "Camera permission denied"
        case .microphoneUnauthorized: return "Microphone permission denied"
        case .deviceHasNoCamera: return "This device has no camera"
        case .deviceHasNoMicrophone: return "This device has no microphone"
        case .unknown(let reason): return reason
        }
    }
}

#if DEBUG
extension VerificationViewModel {
    static func preview(state: VerificationState = .idle) -> VerificationViewModel {
        let viewModel = VerificationViewModel(
            createSessionUseCase: PreviewCreateVerificationSessionUseCase(),
            startVerificationUseCase: PreviewStartVerificationUseCase()
        )
        viewModel.state = state
        return viewModel
    }
}

private struct PreviewCreateVerificationSessionUseCase: CreateVerificationSessionUseCaseProtocol {
    func execute() async throws -> VerificationSession {
        VerificationSession(id: "preview", url: URL(string: "https://preview.veriff.local")!)
    }
}

@MainActor
private struct PreviewStartVerificationUseCase: StartVerificationUseCaseProtocol {
    func execute(session: VerificationSession) async -> VerificationResult {
        try? await Task.sleep(for: .seconds(1))
        return .completed
    }
}
#endif
