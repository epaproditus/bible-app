import XCTest
@testable import bible_app

final class BibleBookTests: XCTestCase {

    // MARK: - Book Count

    func test_totalBooks_is66() {
        XCTAssertEqual(BibleBook.allBooks.count, 66, "There should be exactly 66 books in the Protestant canon")
    }

    func test_oldTestamentCount_is39() {
        XCTAssertEqual(BibleBook.count(for: .oldTestament), 39, "There should be 39 books in the Old Testament")
    }

    func test_newTestamentCount_is27() {
        XCTAssertEqual(BibleBook.count(for: .newTestament), 27, "There should be 27 books in the New Testament")
    }

    // MARK: - Chapter Count Accuracy

    func test_genesis_capsAt50() {
        let genesis = BibleBook.findByFullName("Genesis")
        XCTAssertNotNil(genesis)
        XCTAssertEqual(genesis?.chapterCount, 50, "Genesis has 50 chapters")
    }

    func test_psalms_capsAt150() {
        let psalms = BibleBook.findByFullName("Psalms")
        XCTAssertNotNil(psalms)
        XCTAssertEqual(psalms?.chapterCount, 150, "Psalms has 150 chapters")
    }

    func test_revelation_capsAt22() {
        let revelation = BibleBook.findByFullName("Revelation")
        XCTAssertNotNil(revelation)
        XCTAssertEqual(revelation?.chapterCount, 22, "Revelation has 22 chapters")
    }

    func test_deuteronomy_capsAt34() {
        let deut = BibleBook.findByFullName("Deuteronomy")
        XCTAssertNotNil(deut)
        XCTAssertEqual(deut?.chapterCount, 34, "Deuteronomy has 34 chapters")
    }

    func test_isaiah_capsAt66() {
        let isaiah = BibleBook.findByFullName("Isaiah")
        XCTAssertNotNil(isaiah)
        XCTAssertEqual(isaiah?.chapterCount, 66, "Isaiah has 66 chapters")
    }

    // MARK: - Single-Chapter Books

    func test_singleChapterBooks_areFlagged() {
        let singleChapterNames = BibleBook.singleChapterBooks.map(\.fullName).sorted()
        let expected = ["2 John", "3 John", "Jude", "Obadiah", "Philemon"]
        XCTAssertEqual(singleChapterNames, expected, "Exactly 5 books have 1 chapter")
    }

    func test_obadiah_isSingleChapter() {
        let obadiah = BibleBook.findByFullName("Obadiah")
        XCTAssertNotNil(obadiah)
        XCTAssertTrue(obadiah!.isSingleChapter, "Obadiah should be flagged as single-chapter")
        XCTAssertEqual(obadiah?.chapterCount, 1)
    }

    func test_jude_isSingleChapter() {
        let jude = BibleBook.findByFullName("Jude")
        XCTAssertNotNil(jude)
        XCTAssertTrue(jude!.isSingleChapter, "Jude should be flagged as single-chapter")
    }

    func test_philemon_isSingleChapter() {
        let philemon = BibleBook.findByFullName("Philemon")
        XCTAssertNotNil(philemon)
        XCTAssertTrue(philemon!.isSingleChapter, "Philemon should be flagged as single-chapter")
    }

    func test_2John_isSingleChapter() {
        let book = BibleBook.findByFullName("2 John")
        XCTAssertNotNil(book)
        XCTAssertTrue(book!.isSingleChapter, "2 John should be flagged as single-chapter")
    }

    func test_3John_isSingleChapter() {
        let book = BibleBook.findByFullName("3 John")
        XCTAssertNotNil(book)
        XCTAssertTrue(book!.isSingleChapter, "3 John should be flagged as single-chapter")
    }

    // MARK: - Testament Classification

    func test_genesis_isOldTestament() {
        XCTAssertEqual(BibleBook.findByFullName("Genesis")?.testament, .oldTestament)
    }

    func test_malachi_isOldTestament() {
        XCTAssertEqual(BibleBook.findByFullName("Malachi")?.testament, .oldTestament)
    }

    func test_matthew_isNewTestament() {
        XCTAssertEqual(BibleBook.findByFullName("Matthew")?.testament, .newTestament)
    }

    func test_revelation_isNewTestament() {
        XCTAssertEqual(BibleBook.findByFullName("Revelation")?.testament, .newTestament)
    }

    // MARK: - Canonical Order

    func test_firstBook_isGenesis() {
        XCTAssertEqual(BibleBook.allBooks.first?.fullName, "Genesis")
        XCTAssertEqual(BibleBook.allBooks.first?.id, 1)
    }

    func test_lastBook_isRevelation() {
        XCTAssertEqual(BibleBook.allBooks.last?.fullName, "Revelation")
        XCTAssertEqual(BibleBook.allBooks.last?.id, 66)
    }

    func test_otEndsWithMalachi_ntStartsWithMatthew() {
        let otBooks = BibleBook.oldTestamentBooks
        let ntBooks = BibleBook.newTestamentBooks

        XCTAssertEqual(otBooks.last?.fullName, "Malachi")
        XCTAssertEqual(ntBooks.first?.fullName, "Matthew")
        XCTAssertEqual(otBooks.last?.id, 39)
        XCTAssertEqual(ntBooks.first?.id, 40)
    }

    // MARK: - Lookup Methods

    func test_findByAbbreviation() {
        XCTAssertEqual(BibleBook.findByAbbreviation("Gen.")?.fullName, "Genesis")
        XCTAssertEqual(BibleBook.findByAbbreviation("Rev.")?.fullName, "Revelation")
        XCTAssertEqual(BibleBook.findByAbbreviation("S.S.")?.fullName, "Song of Solomon")
        XCTAssertNil(BibleBook.findByAbbreviation("NONEXISTENT"))
    }

    func test_findByFullName_caseInsensitive() {
        XCTAssertEqual(BibleBook.findByFullName("psalms")?.id, 19)
        XCTAssertEqual(BibleBook.findByFullName("PSALMS")?.id, 19)
        XCTAssertNil(BibleBook.findByFullName("NonExistentBook"))
    }

    func test_findById() {
        XCTAssertEqual(BibleBook.findById(1)?.fullName, "Genesis")
        XCTAssertEqual(BibleBook.findById(66)?.fullName, "Revelation")
        XCTAssertEqual(BibleBook.findById(40)?.fullName, "Matthew")
        XCTAssertNil(BibleBook.findById(0))
        XCTAssertNil(BibleBook.findById(67))
    }

    // MARK: - ID Uniqueness

    func test_allIds_areUniqueAndSequential() {
        let ids = BibleBook.allBooks.map(\.id)
        XCTAssertEqual(ids, Array(1...66), "Book IDs must be 1 through 66 in order")
    }

    // MARK: - LSM Abbreviation Format

    func test_abbreviations_matchLSMDocs() {
        // Spot-check a few abbreviations from the LSM documentation
        XCTAssertEqual(BibleBook.findByFullName("Genesis")?.abbreviation, "Gen.")
        XCTAssertEqual(BibleBook.findByFullName("Exodus")?.abbreviation, "Exo.")
        XCTAssertEqual(BibleBook.findByFullName("Psalms")?.abbreviation, "Psa.")
        XCTAssertEqual(BibleBook.findByFullName("Song of Solomon")?.abbreviation, "S.S.")
        XCTAssertEqual(BibleBook.findByFullName("Matthew")?.abbreviation, "Matt.")
        XCTAssertEqual(BibleBook.findByFullName("1 Corinthians")?.abbreviation, "1 Cor.")
        XCTAssertEqual(BibleBook.findByFullName("Philemon")?.abbreviation, "Philem.")
        XCTAssertEqual(BibleBook.findByFullName("Revelation")?.abbreviation, "Rev.")
    }
}
