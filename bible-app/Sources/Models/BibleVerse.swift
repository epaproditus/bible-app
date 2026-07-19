import Foundation

// MARK: - Public Verse Model

/// A single Bible verse returned from the LSM Recovery Version API.
public struct Verse: Identifiable, Hashable, Sendable {
    /// Unique identifier — the ref string (e.g. "Gen. 1:1")
    public var id: String { ref }
    /// Formatted reference, e.g. "Gen. 1:1"
    public let ref: String
    /// The verse text content
    public let text: String
    /// URL path component for linking to text.recoveryversion.bible
    public let urlpfx: String

    public init(ref: String, text: String, urlpfx: String) {
        self.ref = ref
        self.text = text
        self.urlpfx = urlpfx
    }
}

// MARK: - LSM API Response Models

/// Top-level response from the LSM Recovery Version JSON API.
struct LSMResponse: Decodable {
    let inputstring: String
    let detected: String
    let verses: [LSMVerse]
    let message: String
    let copyright: String
}

/// A single verse as it appears in the LSM API JSON response.
struct LSMVerse: Decodable {
    let ref: String
    let text: String
    let urlpfx: String
}

// MARK: - Error Types

/// Errors that can occur when using the LSM Recovery Version API.
enum LSMAPIError: Error, LocalizedError, Equatable {
    /// Authentication failed (invalid app ID or token).
    case authenticationFailed
    /// A network-level error (timeout, no connection, etc.).
    case networkError(String)
    /// The server returned an unexpected response format.
    case invalidResponse
    /// The API returned a message indicating an issue.
    case apiError(String)
    /// The request exceeded the maximum of 50 verses per call.
    case verseLimitExceeded(count: Int)
    /// Failed to decode the JSON response.
    case decodingError(String)

    var errorDescription: String? {
        switch self {
        case .authenticationFailed:
            return "Authentication failed. Check your app ID and token."
        case .networkError(let detail):
            return "Network error: \(detail)"
        case .invalidResponse:
            return "The server returned an unexpected response."
        case .apiError(let msg):
            return "API error: \(msg)"
        case .verseLimitExceeded(let count):
            return "Request exceeds the 50-verse limit (\(count) verses requested). Narrow your reference range."
        case .decodingError(let detail):
            return "Failed to read the response: \(detail)"
        }
    }
}
