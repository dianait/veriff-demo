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
        state = await verificationProvider.verify().state
    }

    func resetSession() async {
        await verificationProvider.invalidateSession()
        state = .idle
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
    func invalidateSession() async {}
}
#endif
