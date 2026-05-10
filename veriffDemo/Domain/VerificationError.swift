import Foundation

enum VerificationError: Error, Equatable {
    case missingConfiguration
    case invalidSession
    case network
    case unknown(reason: String)
    
    var message: String {
        switch self {
        case .missingConfiguration: return "Add VeriffAPIKey to veriffDemo/Secrets.plist and re-run"
        case .invalidSession: return "Invalid verification session"
        case .network: return "Network error"
        case .unknown(let reason): return reason
        }
    }
}
