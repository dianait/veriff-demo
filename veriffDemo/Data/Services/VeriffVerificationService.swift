import Foundation
import Veriff

@MainActor
final class VeriffVerificationService: NSObject, VerificationServiceProtocol {
    private let veriff = VeriffSdk.shared
    private var continuation: CheckedContinuation<VerificationResult, Never>?

    override init() {
        super.init()
        veriff.delegate = self
    }

    func start(session: VerificationSession) async -> VerificationResult {
        await withCheckedContinuation { continuation in
            self.continuation = continuation
            veriff.startAuthentication(sessionUrl: session.url.absoluteString)
        }
    }

    private func finish(with result: VerificationResult) {
        continuation?.resume(returning: result)
        continuation = nil
    }
}

extension VeriffVerificationService: VeriffSdkDelegate {
    nonisolated func sessionDidEndWithResult(_ result: VeriffSdk.Result) {
        Task { @MainActor [weak self] in
            self?.finish(with: VeriffResultMapper.toDomain(result))
        }
    }

    nonisolated func nfcDataExtracted(_ data: VeriffSdk.NFCData) {}
    nonisolated func nfcDataExtractionFailed() {}
}
