import Foundation

nonisolated struct VerificationSession: Equatable, Codable {
    static let maxLifetime: TimeInterval = 7 * 24 * 60 * 60

    let id: String
    let url: URL
    let createdAt: Date

    func isExpired(now: Date = Date(), maxAge: TimeInterval = maxLifetime) -> Bool {
        now.timeIntervalSince(createdAt) >= maxAge
    }
}
