import Foundation

nonisolated struct CreateSessionRequestDTO: Encodable {
    let verification: Verification

    init(vendorData: String? = nil, endUserId: String? = nil) {
        self.verification = Verification(vendorData: vendorData, endUserId: endUserId)
    }

    struct Verification: Encodable {
        let vendorData: String?
        let endUserId: String?
    }
}
