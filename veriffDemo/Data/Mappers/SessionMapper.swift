import Foundation

nonisolated enum SessionMapper {
    static func toDomain(_ dto: CreateSessionResponseDTO, now: Date = Date()) throws -> VerificationSession {
        guard let url = URL(string: dto.verification.url) else {
            throw VerificationError.invalidSession
        }
        return VerificationSession(id: dto.verification.id, url: url, createdAt: now)
    }
}
