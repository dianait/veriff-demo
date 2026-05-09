import Foundation

nonisolated enum VerificationError: Error, Equatable {
    case missingConfiguration
    case invalidSession
    case network
    case cameraUnauthorized
    case microphoneUnauthorized
    case deviceHasNoCamera
    case deviceHasNoMicrophone
    case unknown(reason: String)
}
