import Testing
import Foundation
@testable import veriffDemo

struct SessionMapperTests {
    @Test("Maps a well-formed DTO to a domain VerificationSession")
    func mapsValidDTO() throws {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let dto = CreateSessionResponseDTO(
            status: "success",
            verification: .init(
                id: "abc-123",
                url: "https://magic.verify.veriff.me/v/abc",
                vendorData: nil,
                endUserId: nil,
                host: nil,
                status: "created",
                sessionToken: nil
            )
        )

        let session = try SessionMapper.toDomain(dto, now: now)

        #expect(session.id == "abc-123")
        #expect(session.url.absoluteString == "https://magic.verify.veriff.me/v/abc")
        #expect(session.createdAt == now)
    }

    @Test("Throws .invalidSession when the URL field is empty")
    func throwsOnEmptyURL() {
        let dto = CreateSessionResponseDTO(
            status: "success",
            verification: .init(
                id: "abc",
                url: "",
                vendorData: nil,
                endUserId: nil,
                host: nil,
                status: "created",
                sessionToken: nil
            )
        )

        #expect(throws: VerificationError.invalidSession) {
            try SessionMapper.toDomain(dto)
        }
    }
}
