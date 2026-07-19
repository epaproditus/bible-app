import XCTest
@testable import bible_app

// MARK: - Mock URLProtocol

/// URLProtocol subclass that intercepts requests and returns canned data.
/// Used to test BibleAPIService without hitting the real LSM API.
final class MockURLProtocol: URLProtocol {
    nonisolated(unsafe) static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let handler = Self.requestHandler else {
            XCTFail("No requestHandler set on MockURLProtocol")
            return
        }

        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

// MARK: - Test Helpers

func makeMockSession() -> URLSession {
    let config = URLSessionConfiguration.ephemeral
    config.protocolClasses = [MockURLProtocol.self]
    return URLSession(configuration: config)
}

// MARK: - Tests

final class BibleAPIServiceTests: XCTestCase {

    // MARK: - fetchChapter

    func test_fetchChapter_returnsAllVersesForChapter() async throws {
        let session = makeMockSession()
        let jsonData = """
        {
            "inputstring": "Matt. 1",
            "detected": "Matt. 1",
            "verses": [
                {"ref": "Matt. 1:1", "text": "The book of the generation of Jesus Christ, the son of David, the son of Abraham.", "urlpfx": "Matt/1/1"},
                {"ref": "Matt. 1:2", "text": "Abraham begot Isaac, and Isaac begot Jacob, and Jacob begot Judah and his brothers,", "urlpfx": "Matt/1/2"}
            ],
            "message": "",
            "copyright": "Verses accessed from the Holy Bible Recovery Version (c) 2024 Living Stream Ministry"
        }
        """.data(using: .utf8)!

        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: "HTTP/1.1",
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, jsonData)
        }

        let service = BibleAPIService.createForTesting(session: session)
        let (verses, copyright) = try await service.fetchChapter(book: "Matt.", chapter: 1)

        XCTAssertEqual(verses.count, 2, "Should return 2 verses for Matt. 1")
        XCTAssertEqual(verses[0].ref, "Matt. 1:1")
        XCTAssertEqual(verses[0].text, "The book of the generation of Jesus Christ, the son of David, the son of Abraham.")
        XCTAssertEqual(verses[0].urlpfx, "Matt/1/1")
        XCTAssertEqual(verses[1].ref, "Matt. 1:2")
        XCTAssertEqual(copyright, "Verses accessed from the Holy Bible Recovery Version (c) 2024 Living Stream Ministry")
    }

    // MARK: - fetchVerses with semicolon-separated references

    func test_fetchVerses_withSemicolonSeparatedRefs() async throws {
        let session = makeMockSession()
        let jsonData = """
        {
            "inputstring": "Prov. 29:18; Acts 26:19",
            "detected": "Prov. 29:18; Acts 26:19",
            "verses": [
                {"ref": "Prov. 29:18", "text": "Where there is no vision, the people cast off restraint; But happy is he who keeps the law.", "urlpfx": "Prov/29/18"},
                {"ref": "Acts 26:19", "text": "Therefore, King Agrippa, I was not disobedient to the heavenly vision,", "urlpfx": "Acts/26/19"}
            ],
            "message": "",
            "copyright": "Verses accessed from the Holy Bible Recovery Version (c) 2024 Living Stream Ministry"
        }
        """.data(using: .utf8)!

        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: "HTTP/1.1",
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, jsonData)
        }

        let service = BibleAPIService.createForTesting(session: session)
        let (verses, _) = try await service.fetchVerses("Prov. 29:18; Acts 26:19")

        XCTAssertEqual(verses.count, 2)
        XCTAssertEqual(verses[0].ref, "Prov. 29:18")
        XCTAssertEqual(verses[1].ref, "Acts 26:19")
    }

    // MARK: - 50-verse cap warning

    func test_fetchVerses_warnsWhenExceeding50Verses() async throws {
        let session = makeMockSession()

        // Build a response with 51 verses — exceeds the documented cap
        var versesArray: [[String: String]] = []
        for i in 1...51 {
            versesArray.append([
                "ref": "Psa. \(i):1",
                "text": "Verse \(i)",
                "urlpfx": "Psa/\(i)/1"
            ])
        }
        let jsonData = try JSONSerialization.data(withJSONObject: [
            "inputstring": "Psa. 1-150",
            "detected": "Psa. 1-150",
            "verses": versesArray,
            "message": "",
            "copyright": "(c) 2024 LSM"
        ])

        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: "HTTP/1.1",
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, jsonData)
        }

        let service = BibleAPIService.createForTesting(session: session)

        do {
            _ = try await service.fetchVerses("Psa. 1")
            XCTFail("Expected verseLimitExceeded error")
        } catch let error as LSMAPIError {
            switch error {
            case .verseLimitExceeded(let count):
                XCTAssertEqual(count, 51, "Should report 51 verses exceeded")
            default:
                XCTFail("Expected verseLimitExceeded, got \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    // MARK: - API-level message surfaced

    func test_fetchVerses_surfacesAPIMessage() async throws {
        let session = makeMockSession()
        let jsonData = """
        {
            "inputstring": "Bad Ref",
            "detected": "",
            "verses": [],
            "message": "Error: The input could not be understood.",
            "copyright": ""
        }
        """.data(using: .utf8)!

        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: "HTTP/1.1",
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, jsonData)
        }

        let service = BibleAPIService.createForTesting(session: session)

        do {
            _ = try await service.fetchVerses("Bad Ref")
            XCTFail("Expected apiError")
        } catch let error as LSMAPIError {
            switch error {
            case .apiError(let msg):
                XCTAssertTrue(msg.contains("could not be understood"))
            default:
                XCTFail("Expected apiError, got \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    // MARK: - Authentication failure (401)

    func test_fetchVerses_authenticationFailure_401() async throws {
        let session = makeMockSession()

        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 401,
                httpVersion: "HTTP/1.1",
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, Data())
        }

        let service = BibleAPIService.createForTesting(session: session)

        do {
            _ = try await service.fetchVerses("Gen. 1:1")
            XCTFail("Expected authenticationFailed")
        } catch let error as LSMAPIError {
            XCTAssertEqual(error, .authenticationFailed)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    // MARK: - Authentication failure (403)

    func test_fetchVerses_authenticationFailure_403() async throws {
        let session = makeMockSession()

        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 403,
                httpVersion: "HTTP/1.1",
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, Data())
        }

        let service = BibleAPIService.createForTesting(session: session)

        do {
            _ = try await service.fetchVerses("Gen. 1:1")
            XCTFail("Expected authenticationFailed")
        } catch let error as LSMAPIError {
            XCTAssertEqual(error, .authenticationFailed)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    // MARK: - Network error handling

    func test_fetchVerses_networkError() async throws {
        let session = makeMockSession()

        MockURLProtocol.requestHandler = { _ in
            throw URLError(.notConnectedToInternet)
        }

        let service = BibleAPIService.createForTesting(session: session)

        do {
            _ = try await service.fetchVerses("Gen. 1:1")
            XCTFail("Expected networkError")
        } catch let error as LSMAPIError {
            switch error {
            case .networkError:
                break // Expected
            default:
                XCTFail("Expected networkError, got \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    // MARK: - Copyright attribution surfaced

    func test_fetchVerses_copyrightAttributionReturned() async throws {
        let session = makeMockSession()
        let jsonData = """
        {
            "inputstring": "John 3:16",
            "detected": "John 3:16",
            "verses": [
                {"ref": "John 3:16", "text": "For God so loved the world that He gave His only begotten Son...", "urlpfx": "John/3/16"}
            ],
            "message": "",
            "copyright": "Verses accessed from the Holy Bible Recovery Version (c) 2024 Living Stream Ministry"
        }
        """.data(using: .utf8)!

        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: "HTTP/1.1",
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, jsonData)
        }

        let service = BibleAPIService.createForTesting(session: session)
        let (_, copyright) = try await service.fetchVerses("John 3:16")

        XCTAssertFalse(copyright.isEmpty, "Copyright attribution must not be empty")
        XCTAssertTrue(copyright.contains("Living Stream Ministry"), "Copyright must reference LSM")
    }

    // MARK: - Basic Auth header present

    func test_service_sendsBasicAuthHeader() async throws {
        let session = makeMockSession()
        let expectation = expectation(description: "Request made")

        MockURLProtocol.requestHandler = { request in
            let authHeader = request.value(forHTTPHeaderField: "Authorization")
            XCTAssertNotNil(authHeader, "Authorization header must be present")
            XCTAssertTrue(authHeader!.hasPrefix("Basic "), "Must use Basic auth scheme")

            // Verify base64 encoding of "test:test"
            let expectedBase64 = Data("test:test".utf8).base64EncodedString()
            XCTAssertEqual(authHeader, "Basic \(expectedBase64)")

            expectation.fulfill()

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: "HTTP/1.1",
                headerFields: ["Content-Type": "application/json"]
            )!
            let data = """
            {"inputstring":"","detected":"","verses":[],"message":"","copyright":""}
            """.data(using: .utf8)!
            return (response, data)
        }

        let service = BibleAPIService.createForTesting(appID: "test", token: "test", session: session)
        _ = try? await service.fetchVerses("Gen. 1:1")

        await fulfillment(of: [expectation], timeout: 1.0)
    }

    // MARK: - Accept header is JSON

    func test_service_sendsAcceptJsonHeader() async throws {
        let session = makeMockSession()

        MockURLProtocol.requestHandler = { request in
            let acceptHeader = request.value(forHTTPHeaderField: "Accept")
            XCTAssertEqual(acceptHeader, "application/json", "Must request JSON responses")

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: "HTTP/1.1",
                headerFields: ["Content-Type": "application/json"]
            )!
            let data = """
            {"inputstring":"","detected":"","verses":[],"message":"","copyright":""}
            """.data(using: .utf8)!
            return (response, data)
        }

        let service = BibleAPIService.createForTesting(session: session)
        _ = try? await service.fetchVerses("Gen. 1:1")
    }

    // MARK: - JSON decoding error

    func test_fetchVerses_decodingErrorOnBadJSON() async throws {
        let session = makeMockSession()
        let badData = "not valid json".data(using: .utf8)!

        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: "HTTP/1.1",
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, badData)
        }

        let service = BibleAPIService.createForTesting(session: session)

        do {
            _ = try await service.fetchVerses("Gen. 1:1")
            XCTFail("Expected decodingError")
        } catch let error as LSMAPIError {
            switch error {
            case .decodingError:
                break // Expected
            default:
                XCTFail("Expected decodingError, got \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    // MARK: - LSMResponse models

    func test_LSMResponse_decodesCorrectly() throws {
        let json = """
        {
            "inputstring": "John 1:1",
            "detected": "John 1:1",
            "verses": [
                {"ref": "John 1:1", "text": "In the beginning was the Word...", "urlpfx": "John/1/1"}
            ],
            "message": "",
            "copyright": "(c) 2024 LSM"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let response = try decoder.decode(LSMResponse.self, from: json)

        XCTAssertEqual(response.inputstring, "John 1:1")
        XCTAssertEqual(response.detected, "John 1:1")
        XCTAssertEqual(response.verses.count, 1)
        XCTAssertEqual(response.verses[0].ref, "John 1:1")
        XCTAssertEqual(response.verses[0].text, "In the beginning was the Word...")
        XCTAssertEqual(response.verses[0].urlpfx, "John/1/1")
        XCTAssertEqual(response.copyright, "(c) 2024 LSM")
        XCTAssertTrue(response.message.isEmpty)
    }
}
