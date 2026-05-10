import Testing
import Foundation
@testable import veriffDemo

struct SessionMapperTests {
    @Test("Maps a well-formed DTO to a domain VerificationSession")
    func mapsValidDTO() throws {
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

        let session = try SessionMapper.toDomain(dto)

        #expect(session.id == "abc-123")
        #expect(session.url.absoluteString == "https://magic.verify.veriff.me/v/abc")
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
