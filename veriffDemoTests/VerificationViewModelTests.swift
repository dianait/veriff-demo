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

    @Test("resetSession invalidates the provider's session and returns to idle")
    func resetSessionReturnsToIdle() async {
        let provider = RecordingVerificationProvider(result: .completed)
        let viewModel = VerificationViewModel(verificationProvider: provider)

        await viewModel.startVerification()
        #expect(viewModel.state == .completed)

        await viewModel.resetSession()

        #expect(viewModel.state == .idle)
        #expect(await provider.invalidateCallCount == 1)
    }

    @Test("resetSession from idle still invalidates the provider")
    func resetSessionFromIdle() async {
        let provider = RecordingVerificationProvider(result: .completed)
        let viewModel = VerificationViewModel(verificationProvider: provider)

        await viewModel.resetSession()

        #expect(viewModel.state == .idle)
        #expect(await provider.invalidateCallCount == 1)
    }

    @Test("Multiple resetSession calls each invalidate the provider")
    func resetSessionCallsAccumulate() async {
        let provider = RecordingVerificationProvider(result: .completed)
        let viewModel = VerificationViewModel(verificationProvider: provider)

        await viewModel.resetSession()
        await viewModel.resetSession()
        await viewModel.resetSession()

        #expect(await provider.invalidateCallCount == 3)
    }
}

private struct StubVerificationProvider: VerificationProviderProtocol {
    let result: VerificationResult
    func verify() async -> VerificationResult { result }
    func invalidateSession() async {}
}

private actor RecordingVerificationProvider: VerificationProviderProtocol {
    let result: VerificationResult
    private(set) var invalidateCallCount = 0

    init(result: VerificationResult) {
        self.result = result
    }

    func verify() async -> VerificationResult { result }

    func invalidateSession() async {
        invalidateCallCount += 1
    }
}

private actor SuspendingVerificationProvider: VerificationProviderProtocol {
    private var continuation: CheckedContinuation<VerificationResult, Never>?
    private var startedContinuation: CheckedContinuation<Void, Never>?

    nonisolated func verify() async -> VerificationResult {
        await withCheckedContinuation { continuation in
            Task { await self.store(continuation) }
        }
    }

    func invalidateSession() async {}

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
