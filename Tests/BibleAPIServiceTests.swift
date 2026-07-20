import XCTest
@testable import bible_app

final class BibleAPIServiceTests: XCTestCase {

    override func setUp() {
        super.setUp()
        BibleAPIService.clearCache()
    }

    // MARK: - Loading

    func test_loadsGenesisChapter1_has31Verses() {
        let verses = BibleAPIService.verses(for: "Gen", chapter: 1)
        XCTAssertEqual(verses.count, 31, "Genesis 1 should have 31 verses")
    }

    func test_verses_areInCanonicalOrder() {
        let verses = BibleAPIService.verses(for: "Gen", chapter: 1)
        let verseNumbers = verses.map(\.verse)
        XCTAssertEqual(verseNumbers, Array(1...31), "Verses must be in order 1-31")
    }

    func test_genesis1_1_hasCorrectText() {
        let verses = BibleAPIService.verses(for: "Gen", chapter: 1)
        let gen1_1 = verses.first
        XCTAssertNotNil(gen1_1)
        XCTAssertEqual(gen1_1?.verse, 1)
        XCTAssertTrue(gen1_1!.text.contains("beginning"), "Gen 1:1 should contain 'beginning'")
    }

    func test_genesis1_31_hasCorrectVerseNumber() {
        let verses = BibleAPIService.verses(for: "Gen", chapter: 1)
        let last = verses.last
        XCTAssertNotNil(last)
        XCTAssertEqual(last?.verse, 31, "Last verse of Genesis 1 should be verse 31")
    }

    // MARK: - Multi-chapter books

    func test_revelation22_has21Verses() {
        let verses = BibleAPIService.verses(for: "Rev", chapter: 22)
        XCTAssertEqual(verses.count, 21, "Revelation 22 should have 21 verses")
    }

    func test_psalms1_has6Verses() {
        let verses = BibleAPIService.verses(for: "Psa", chapter: 1)
        XCTAssertEqual(verses.count, 6, "Psalm 1 should have 6 verses")
    }

    func test_psalms150_has6Verses() {
        let verses = BibleAPIService.verses(for: "Psa", chapter: 150)
        XCTAssertEqual(verses.count, 6, "Psalm 150 should have 6 verses")
    }

    func test_matthew1_has25Verses() {
        let verses = BibleAPIService.verses(for: "Mat", chapter: 1)
        XCTAssertEqual(verses.count, 25, "Matthew 1 should have 25 verses")
    }

    func test_matthew28_has20Verses() {
        let verses = BibleAPIService.verses(for: "Mat", chapter: 28)
        XCTAssertEqual(verses.count, 20, "Matthew 28 should have 20 verses")
    }

    func test_john3_has36Verses() {
        let verses = BibleAPIService.verses(for: "Joh", chapter: 3)
        XCTAssertEqual(verses.count, 36, "John 3 should have 36 verses")
    }

    func test_john1_has51Verses() {
        let verses = BibleAPIService.verses(for: "Joh", chapter: 1)
        XCTAssertEqual(verses.count, 51, "John 1 should have 51 verses")
    }

    // MARK: - Single-chapter books

    func test_obadiah1_has21Verses() {
        let verses = BibleAPIService.verses(for: "Oba", chapter: 1)
        XCTAssertEqual(verses.count, 21, "Obadiah should have 21 verses")
    }

    func test_philemon1_has25Verses() {
        let verses = BibleAPIService.verses(for: "Phm", chapter: 1)
        XCTAssertEqual(verses.count, 25, "Philemon should have 25 verses")
    }

    func test_2john1_has13Verses() {
        let verses = BibleAPIService.verses(for: "2Jo", chapter: 1)
        XCTAssertEqual(verses.count, 13, "2 John should have 13 verses")
    }

    func test_3john1_has14Verses() {
        let verses = BibleAPIService.verses(for: "3Jo", chapter: 1)
        XCTAssertEqual(verses.count, 14, "3 John should have 14 verses")
    }

    func test_jude1_has25Verses() {
        let verses = BibleAPIService.verses(for: "Jud", chapter: 1)
        XCTAssertEqual(verses.count, 25, "Jude should have 25 verses")
    }

    // MARK: - Missing data

    func test_unknownBookCode_returnsEmpty() {
        let verses = BibleAPIService.verses(for: "NONEXISTENT", chapter: 1)
        XCTAssertTrue(verses.isEmpty, "Unknown book code should return empty array")
    }

    func test_unknownChapter_returnsEmpty() {
        let verses = BibleAPIService.verses(for: "Gen", chapter: 999)
        XCTAssertTrue(verses.isEmpty, "Unknown chapter should return empty array")
    }

    // MARK: - Cache

    func test_cache_returnsSameResults() {
        let first = BibleAPIService.verses(for: "Gen", chapter: 1)
        let second = BibleAPIService.verses(for: "Gen", chapter: 1)
        XCTAssertEqual(first.count, second.count)
        XCTAssertEqual(first.first?.text, second.first?.text)
    }

    func test_clearCache_forcesReload() {
        let verses = BibleAPIService.verses(for: "Gen", chapter: 1)
        XCTAssertFalse(verses.isEmpty)

        BibleAPIService.clearCache()
        let reloaded = BibleAPIService.verses(for: "Gen", chapter: 1)
        XCTAssertEqual(reloaded.count, verses.count)
    }

    // MARK: - Footnotes

    func test_verse_footnoteMarkers_areNotEmpty() {
        // Genesis 1:1 is known to have footnote markers
        let verses = BibleAPIService.verses(for: "Gen", chapter: 1)
        let gen1_1 = verses.first
        XCTAssertNotNil(gen1_1)
        XCTAssertFalse(gen1_1!.footnoteMarkers.isEmpty, "Gen 1:1 should have footnote markers")
    }

    func test_footnoteLookup_returnsFootnote() {
        let fn = BibleAPIService.footnote(id: "n1_1x1a", in: "Gen")
        XCTAssertNotNil(fn, "Footnote n1_1x1a should exist in Genesis")
        XCTAssertEqual(fn?.marker, "1a")
        XCTAssertFalse(fn!.text.isEmpty, "Footnote text should not be empty")
    }

    func test_footnotesForVerse_returnsExpectedCount() {
        let fns = BibleAPIService.footnotes(for: "Gen", chapter: 1, verse: 1)
        XCTAssertFalse(fns.isEmpty, "Gen 1:1 should have footnotes")
    }

    func test_unknownFootnote_returnsNil() {
        let fn = BibleAPIService.footnote(id: "nonexistent", in: "Gen")
        XCTAssertNil(fn)
    }

    // MARK: - Copyright

    func test_copyright_returnsNonEmpty() {
        let copyright = BibleAPIService.copyright(for: "Gen")
        XCTAssertFalse(copyright.isEmpty, "Copyright should not be empty")
        XCTAssertTrue(copyright.contains("Living Stream Ministry"), "Copyright must reference LSM")
    }

    func test_copyright_fallback() {
        let copyright = BibleAPIService.copyright(for: "NONEXISTENT")
        XCTAssertFalse(copyright.isEmpty, "Fallback copyright should not be empty")
    }

    // MARK: - Preload

    func test_preload_doesNotThrow() {
        // Should not crash
        BibleAPIService.preload(bookCode: "Gen")
        BibleAPIService.preload(bookCode: "Rev")
        // Verify it was cached
        let verses = BibleAPIService.verses(for: "Gen", chapter: 1)
        XCTAssertEqual(verses.count, 31)
    }

    // MARK: - All 66 books load without error

    func test_allBooks_loadSuccessfully() {
        let codes = BibleDataService.books.map(\.code)
        for code in codes {
            let verses = BibleAPIService.verses(for: code, chapter: 1)
            XCTAssertFalse(verses.isEmpty, "\(code) chapter 1 should load verses")
        }
    }

    // MARK: - Verse ID Format

    func test_verseID_format() {
        let verses = BibleAPIService.verses(for: "Gen", chapter: 1)
        let gen1_1 = verses.first
        XCTAssertEqual(gen1_1?.id, "1_1", "Verse ID should be chapter_verse format")
    }

    func test_genesis1_verseCountMatchesSource() {
        // The source HTML data for the Recovery Version Genesis 1 has 31 verses
        let verses = BibleAPIService.verses(for: "Gen", chapter: 1)
        XCTAssertEqual(verses.count, 31, "Genesis 1 must have 31 verses matching the source HTML data")
    }
}
