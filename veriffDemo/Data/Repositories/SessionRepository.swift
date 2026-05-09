import Foundation

nonisolated struct SessionRepository: SessionRepositoryProtocol {
    private let demoSessionURL: String

    init(demoSessionURL: String) {
        self.demoSessionURL = demoSessionURL
    }

    func createSession() async throws -> VerificationSession {
        guard let url = URL(string: demoSessionURL) else {
            throw VerificationError.invalidSession
        }
        return VerificationSession(id: "demo-session-id", url: url)
    }
}

// MARK: - Production reference (intentionally commented out)
//
// In a real integration this method would NOT return a hardcoded URL. There are two
// valid approaches; (1) is the recommended one and is what Veriff's architecture
// assumes.
//
// (1) RECOMMENDED — call YOUR backend:
//     The mobile app POSTs to your own backend (authenticated as the end-user).
//     Your backend calls Veriff's POST /v1/sessions with the private X-AUTH-CLIENT
//     API key and returns only the resulting `verification.url` to the app.
//     Why this is the recommended path:
//       · the Veriff API key never ships in the mobile binary
//       · the session is bound to the authenticated user on your side
//       · you can apply rate limiting, fraud signals, and analytics
//       · you persist the user ↔ Veriff session mapping for webhooks
//
//     final class BackendSessionRepository: SessionRepositoryProtocol {
//         private let baseURL: URL
//         private let session: URLSession
//         private let authToken: () async throws -> String
//
//         func createSession() async throws -> VerificationSession {
//             var request = URLRequest(url: baseURL.appendingPathComponent("verifications"))
//             request.httpMethod = "POST"
//             request.setValue("application/json", forHTTPHeaderField: "Content-Type")
//             request.setValue("Bearer \(try await authToken())", forHTTPHeaderField: "Authorization")
//
//             let (data, response) = try await session.data(for: request)
//             guard let http = response as? HTTPURLResponse,
//                   (200..<300).contains(http.statusCode) else {
//                 throw VerificationError.network
//             }
//             let payload = try JSONDecoder().decode(BackendSessionResponse.self, from: data)
//             guard let url = URL(string: payload.url) else { throw VerificationError.invalidSession }
//             return VerificationSession(id: payload.id, url: url)
//         }
//     }
//
// (2) DIRECT to Veriff — possible but discouraged:
//     The app could call Veriff's POST /v1/sessions itself, but that ships
//     X-AUTH-CLIENT inside the mobile binary, which is trivially extractable.
//     Only acceptable in fully-trusted sandbox/test environments.
//
//     POST https://stationapi.veriff.com/v1/sessions
//     Headers:
//         Content-Type:  application/json
//         X-AUTH-CLIENT: <your-api-key>
//     Body:
//         { "verification": {} }
//     Response (excerpt):
//         { "status": "success",
//           "verification": { "id": "...", "url": "https://alchemy.veriff.com/v/..." } }
//
// In both cases the rest of the app is unchanged: the use case keeps calling
// `SessionRepositoryProtocol.createSession()` and the ViewModel keeps consuming
// `VerificationSession`. That is the value of putting the protocol in Domain.
