import XCTest
@testable import bible_app

final class BibleBookTests: XCTestCase {

    // MARK: - Book Count

    func test_totalBooks_is66() {
        XCTAssertEqual(BibleDataService.books.count, 66, "There should be exactly 66 books in the Protestant canon")
    }

    func test_oldTestamentCount_is39() {
        XCTAssertEqual(BibleDataService.oldTestament.count, 39, "There should be 39 books in the Old Testament")
    }

    func test_newTestamentCount_is27() {
        XCTAssertEqual(BibleDataService.newTestament.count, 27, "There should be 27 books in the New Testament")
    }

    // MARK: - Chapter Count Accuracy

    func test_genesis_has50Chapters() {
        let genesis = BibleDataService.book(for: "Gen")
        XCTAssertNotNil(genesis)
        XCTAssertEqual(genesis?.chapters, 50, "Genesis has 50 chapters")
    }

    func test_psalms_has150Chapters() {
        let psalms = BibleDataService.book(for: "Psa")
        XCTAssertNotNil(psalms)
        XCTAssertEqual(psalms?.chapters, 150, "Psalms has 150 chapters")
    }

    func test_revelation_has22Chapters() {
        let revelation = BibleDataService.book(for: "Rev")
        XCTAssertNotNil(revelation)
        XCTAssertEqual(revelation?.chapters, 22, "Revelation has 22 chapters")
    }

    func test_deuteronomy_has34Chapters() {
        let deut = BibleDataService.book(for: "Deu")
        XCTAssertNotNil(deut)
        XCTAssertEqual(deut?.chapters, 34, "Deuteronomy has 34 chapters")
    }

    func test_isaiah_has66Chapters() {
        let isaiah = BibleDataService.book(for: "Isa")
        XCTAssertNotNil(isaiah)
        XCTAssertEqual(isaiah?.chapters, 66, "Isaiah has 66 chapters")
    }

    // MARK: - Single-Chapter Books

    func test_singleChapterBooks_haveOneChapter() {
        let singles = BibleDataService.books.filter { $0.chapters == 1 }
        let names = singles.map(\.name).sorted()
        let expected = ["2 John", "3 John", "Jude", "Obadiah", "Philemon"]
        XCTAssertEqual(names, expected, "Exactly 5 books have 1 chapter")
    }

    // MARK: - Testament Classification

    func test_genesis_isOldTestament() {
        XCTAssertEqual(BibleDataService.book(for: "Gen")?.testament, 0)
    }

    func test_malachi_isOldTestament() {
        XCTAssertEqual(BibleDataService.book(for: "Mal")?.testament, 0)
    }

    func test_matthew_isNewTestament() {
        XCTAssertEqual(BibleDataService.book(for: "Mat")?.testament, 1)
    }

    func test_revelation_isNewTestament() {
        XCTAssertEqual(BibleDataService.book(for: "Rev")?.testament, 1)
    }

    // MARK: - Canonical Order

    func test_firstBook_isGenesis() {
        XCTAssertEqual(BibleDataService.books.first?.name, "Genesis")
        XCTAssertEqual(BibleDataService.books.first?.code, "Gen")
    }

    func test_lastBook_isRevelation() {
        XCTAssertEqual(BibleDataService.books.last?.name, "Revelation")
        XCTAssertEqual(BibleDataService.books.last?.code, "Rev")
    }

    func test_otEndsWithMalachi_ntStartsWithMatthew() {
        let otBooks = BibleDataService.oldTestament
        let ntBooks = BibleDataService.newTestament

        XCTAssertEqual(otBooks.last?.name, "Malachi")
        XCTAssertEqual(ntBooks.first?.name, "Matthew")
        XCTAssertEqual(otBooks.last?.code, "Mal")
        XCTAssertEqual(ntBooks.first?.code, "Mat")
    }

    // MARK: - Book Code Lookup

    func test_bookByCode() {
        XCTAssertEqual(BibleDataService.book(for: "Gen")?.name, "Genesis")
        XCTAssertEqual(BibleDataService.book(for: "Rev")?.name, "Revelation")
        XCTAssertEqual(BibleDataService.book(for: "SoS")?.name, "Song of Songs")
        XCTAssertNil(BibleDataService.book(for: "NONEXISTENT"))
    }

    // MARK: - Code Uniqueness

    func test_allCodes_areUnique() {
        let codes = BibleDataService.books.map(\.code)
        let uniqueCodes = Set(codes)
        XCTAssertEqual(codes.count, uniqueCodes.count, "All book codes must be unique")
    }

    // MARK: - Testament Name

    func test_testamentName() {
        XCTAssertEqual(BibleDataService.book(for: "Gen")?.testamentName, "Old Testament")
        XCTAssertEqual(BibleDataService.book(for: "Mat")?.testamentName, "New Testament")
    }

    // MARK: - Chapter Listing

    func test_chapters_forGenesis() {
        let genesis = BibleDataService.book(for: "Gen")!
        let chapters = BibleDataService.chapters(for: genesis)
        XCTAssertEqual(chapters.count, 50)
        XCTAssertEqual(chapters.first, 1)
        XCTAssertEqual(chapters.last, 50)
    }

    func test_chapters_forObadiah() {
        let obadiah = BibleDataService.book(for: "Oba")!
        let chapters = BibleDataService.chapters(for: obadiah)
        XCTAssertEqual(chapters, [1], "Single-chapter book should have just 1 chapter")
    }
}
