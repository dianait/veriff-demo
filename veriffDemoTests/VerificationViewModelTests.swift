import Testing
@testable import veriffDemo

@MainActor
struct VerificationViewModelTests {
    @Test("Completed result transitions to completed state")
    func completed() async {
        let viewModel = VerificationViewModel(
            verificationProvider: StubVerificationProvider(result: .completed)
        )

        await viewModel.startVerification()

        #expect(viewModel.state == .completed)
    }

    @Test("Cancelled result transitions to cancelled state")
    func cancelled() async {
        let viewModel = VerificationViewModel(
            verificationProvider: StubVerificationProvider(result: .cancelled)
        )

        await viewModel.startVerification()

        #expect(viewModel.state == .cancelled)
    }

    @Test(
        "Failed result surfaces the matching user-facing message",
        arguments: [
            (VerificationError.missingConfiguration, "Add VeriffAPIKey to veriffDemo/Secrets.plist and re-run"),
            (.invalidSession, "Invalid verification session"),
            (.network, "Network error"),
            (.unknown(reason: "Boom"), "Boom")
        ]
    )
    func failed(error: VerificationError, expectedMessage: String) async {
        let viewModel = VerificationViewModel(
            verificationProvider: StubVerificationProvider(result: .failed(error))
        )

        await viewModel.startVerification()

        #expect(viewModel.state == .failed(expectedMessage))
    }

    @Test("State is set to loading while verification is in flight")
    func loadingStateExposed() async {
        let provider = SuspendingVerificationProvider()
        let viewModel = VerificationViewModel(verificationProvider: provider)

        let task = Task { await viewModel.startVerification() }
        await provider.waitUntilStarted()

        #expect(viewModel.state == .loading)

        await provider.resume(with: .completed)
        await task.value
        #expect(viewModel.state == .completed)
    }
}

private struct StubVerificationProvider: VerificationProviderProtocol {
    let result: VerificationResult
    func verify() async -> VerificationResult { result }
}

private actor SuspendingVerificationProvider: VerificationProviderProtocol {
    private var continuation: CheckedContinuation<VerificationResult, Never>?
    private var startedContinuation: CheckedContinuation<Void, Never>?

    nonisolated func verify() async -> VerificationResult {
        await withCheckedContinuation { continuation in
            Task { await self.store(continuation) }
        }
    }

    private func store(_ continuation: CheckedContinuation<VerificationResult, Never>) {
        self.continuation = continuation
        startedContinuation?.resume()
        startedContinuation = nil
    }

    func waitUntilStarted() async {
        if continuation != nil { return }
        await withCheckedContinuation { startedContinuation = $0 }
    }

    func resume(with result: VerificationResult) {
        continuation?.resume(returning: result)
        continuation = nil
    }
}
