import Foundation
import Observation

@MainActor
@Observable
final class VerificationViewModel {
    private(set) var state: VerificationState = .idle

    private let verificationProvider: VerificationProviderProtocol

    init(verificationProvider: VerificationProviderProtocol) {
        self.verificationProvider = verificationProvider
    }

    func startVerification() async {
        state = .loading
        let result = await verificationProvider.verify()
        state = map(result)
    }

    private func map(_ result: VerificationResult) -> VerificationState {
        switch result {
        case .completed: return .completed
        case .cancelled: return .cancelled
        case .failed(let error): return .failed(error.message)
        }
    }
}

#if DEBUG
extension VerificationViewModel {
    static func preview(state: VerificationState = .idle) -> VerificationViewModel {
        let viewModel = VerificationViewModel(
            verificationProvider: PreviewVerificationProvider()
        )
        viewModel.state = state
        return viewModel
    }
}

private struct PreviewVerificationProvider: VerificationProviderProtocol {
    func verify() async -> VerificationResult {
        try? await Task.sleep(for: .seconds(1))
        return .completed
    }
}
#endif
