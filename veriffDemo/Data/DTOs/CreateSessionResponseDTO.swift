import Foundation

nonisolated struct CreateSessionResponseDTO: Decodable {
    let status: String
    let verification: Verification

    struct Verification: Decodable {
        let id: String
        let url: String
        let vendorData: String?
        let endUserId: String?
        let host: String?
        let status: String
        let sessionToken: String?
    }
}
