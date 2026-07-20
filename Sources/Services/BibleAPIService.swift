import Foundation

/// Client for the LSM Text Only Holy Bible Recovery Version API.
///
/// Uses Basic Authentication (app ID + token) and returns verses parsed from
/// the JSON endpoint. The API caps requests at 50 verses per call.
///
/// **Usage:**
/// ```swift
/// let service = BibleAPIService(appID: "myApp", token: "abc123")
/// let (verses, copyright) = try await service.fetchChapter(book: "Gen.", chapter: 1)
/// let (verses, copyright) = try await service.fetchVerses("Prov. 29:18; Acts 26:19")
/// ```
public actor BibleAPIService {

    // MARK: - Configuration

    private let baseURL = URL(string: "https://api.lsm.org/recver/txo.php")!
    private let session: URLSession
    private let appID: String
    private let token: String

    /// Maximum verses the LSM API returns per request (documented cap).
    nonisolated static let maxVersesPerRequest = 50

    // MARK: - Init

    public init(
        appID: String,
        token: String,
        session: URLSession = .shared
    ) {
        self.appID = appID
        self.token = token
        self.session = session
    }

    // MARK: - Public API

    /// Fetch all verses for a single chapter.
    ///
    /// - Parameters:
    ///   - abbreviation: LSM book abbreviation with period, e.g. `"Gen."`, `"Matt."`, `"Rev."`
    ///   - chapter: Chapter number (1-based)
    /// - Returns: Tuple of parsed `[Verse]` and the required `copyright` attribution string.
    /// - Throws: `LSMAPIError` on network/auth/parse failures or if the result exceeds the 50-verse cap.
    public func fetchChapter(book abbreviation: String, chapter: Int) async throws -> (verses: [Verse], copyright: String) {
        // Build a reference like "Gen. 1" to fetch the entire chapter
        let reference = "\(abbreviation) \(chapter)"
        return try await fetchVerses(reference)
    }

    /// Fetch verses from a semicolon-separated reference string.
    ///
    /// Supports both standard and complex references, e.g.:
    /// `"Prov. 29:18; Acts 26:19"`
    /// `"John 1:1-5"`
    /// `"Eph. 4:4-6; Rev. 21:2, 9-10"`
    ///
    /// - Parameter reference: A semicolon-separated list of Bible references.
    /// - Returns: Tuple of parsed `[Verse]` and the required `copyright` attribution string.
    /// - Throws: `LSMAPIError` on network/auth/parse failures or if the result exceeds the 50-verse cap.
    public func fetchVerses(_ reference: String) async throws -> (verses: [Verse], copyright: String) {
        let request = try buildRequest(for: reference)

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw LSMAPIError.networkError(error.localizedDescription)
        }

        return try parseResponse(data: data, response: response)
    }

    // MARK: - Request Building

    private func buildRequest(for reference: String) throws -> URLRequest {
        guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else {
            throw LSMAPIError.invalidResponse
        }

        components.queryItems = [
            URLQueryItem(name: "String", value: reference),
            URLQueryItem(name: "Out", value: "json"),
            URLQueryItem(name: "Lang", value: "eng"),
        ]

        guard let url = components.url else {
            throw LSMAPIError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        // Basic Auth: "Basic base64(appid:token)"
        let credentials = "\(appID):\(token)"
        guard let credentialData = credentials.data(using: .utf8) else {
            throw LSMAPIError.authenticationFailed
        }
        let base64Credentials = credentialData.base64EncodedString()
        request.setValue("Basic \(base64Credentials)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        request.timeoutInterval = 30
        return request
    }

    // MARK: - Response Parsing

    private func parseResponse(data: Data, response: URLResponse) throws -> (verses: [Verse], copyright: String) {
        // Check HTTP status
        guard let httpResponse = response as? HTTPURLResponse else {
            throw LSMAPIError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200:
            break // OK
        case 401:
            throw LSMAPIError.authenticationFailed
        case 403:
            throw LSMAPIError.authenticationFailed
        default:
            throw LSMAPIError.networkError("HTTP \(httpResponse.statusCode)")
        }

        // Decode JSON
        let decoder = JSONDecoder()
        let lsmResponse: LSMResponse
        do {
            lsmResponse = try decoder.decode(LSMResponse.self, from: data)
        } catch {
            throw LSMAPIError.decodingError(error.localizedDescription)
        }

        // Check for API-level error messages
        if !lsmResponse.message.isEmpty {
            // If it's a warning about verse count, surface the cap warning
            if lsmResponse.message.localizedCaseInsensitiveContains("50") ||
                lsmResponse.message.localizedCaseInsensitiveContains("limit") ||
                lsmResponse.message.localizedCaseInsensitiveContains("maximum") {
                throw LSMAPIError.verseLimitExceeded(count: lsmResponse.verses.count)
            }
            // Otherwise surface the message
            throw LSMAPIError.apiError(lsmResponse.message)
        }

        // Check verse count cap
        if lsmResponse.verses.count > Self.maxVersesPerRequest {
            throw LSMAPIError.verseLimitExceeded(count: lsmResponse.verses.count)
        }

        let verses = lsmResponse.verses.map { raw in
            Verse(ref: raw.ref, text: raw.text, urlpfx: raw.urlpfx)
        }

        return (verses, lsmResponse.copyright)
    }
}

// MARK: - URLSession Helpers

extension BibleAPIService {
    /// Create a service with a custom URLSession configuration.
    /// Useful for injecting mock URLProtocols in tests.
    nonisolated static func createForTesting(
        appID: String = "test",
        token: String = "test",
        session: URLSession
    ) -> BibleAPIService {
        BibleAPIService(appID: appID, token: token, session: session)
    }
}
