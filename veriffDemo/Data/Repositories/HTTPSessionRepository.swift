import Foundation

nonisolated final class HTTPSessionRepository: SessionRepositoryProtocol {
    private let config: VeriffAPIConfig
    private let session: URLSession
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(
        config: VeriffAPIConfig,
        session: URLSession = .shared,
        encoder: JSONEncoder = JSONEncoder(),
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.config = config
        self.session = session
        self.encoder = encoder
        self.decoder = decoder
    }

    func createSession() async throws -> VerificationSession {
        let endpoint = config.baseURL.appendingPathComponent("v1/sessions")
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(config.apiKey, forHTTPHeaderField: "X-AUTH-CLIENT")
        request.httpBody = try encoder.encode(CreateSessionRequestDTO())

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw VerificationError.network
        }

        let payload = try decoder.decode(CreateSessionResponseDTO.self, from: data)
        return try SessionMapper.toDomain(payload)
    }
}
