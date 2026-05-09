import Foundation

nonisolated struct VeriffAPIConfig {
    let baseURL: URL
    let apiKey: String

    static func loadFromBundle(_ bundle: Bundle = .main) -> VeriffAPIConfig? {
        guard let url = bundle.url(forResource: "Secrets", withExtension: "plist"),
              let data = try? Data(contentsOf: url),
              let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
              let apiKey = plist["VeriffAPIKey"] as? String,
              !apiKey.isEmpty,
              let baseURLString = plist["VeriffBaseURL"] as? String,
              let baseURL = URL(string: baseURLString) else {
            return nil
        }
        return VeriffAPIConfig(baseURL: baseURL, apiKey: apiKey)
    }
}
