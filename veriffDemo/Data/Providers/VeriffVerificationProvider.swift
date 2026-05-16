import Foundation
import Veriff

@MainActor
final class VeriffVerificationProvider: NSObject, VerificationProviderProtocol {
    private let sessionRepository: SessionRepositoryProtocol
    private let veriff = VeriffSdk.shared
    private var continuation: CheckedContinuation<VerificationResult, Never>?
    private var isRunning = false

    init(sessionRepository: SessionRepositoryProtocol) {
        self.sessionRepository = sessionRepository
        super.init()
        veriff.delegate = self
    }

    func invalidateSession() async {
        await sessionRepository.invalidate()
    }

    func verify() async -> VerificationResult {
        guard !isRunning else {
            return .failed(.unknown(reason: "A verification is already in progress"))
        }
        isRunning = true
        defer { isRunning = false }

        do {
            let session = try await sessionRepository.getSession()
            let result = await runSDK(with: session)
            if case .failed = result {
                await sessionRepository.invalidate()
            }
            return result
        } catch let error as VerificationError {
            return .failed(error)
        } catch {
            return .failed(.unknown(reason: "Unexpected error"))
        }
    }

    private func runSDK(with session: VerificationSession) async -> VerificationResult {
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

extension VeriffVerificationProvider: VeriffSdkDelegate {
    nonisolated func sessionDidEndWithResult(_ result: VeriffSdk.Result) {
        Task { @MainActor [weak self] in
            self?.finish(with: VeriffResultMapper.toDomain(result))
        }
    }

    nonisolated func nfcDataExtracted(_ data: VeriffSdk.NFCData) {}
    nonisolated func nfcDataExtractionFailed() {}
}
