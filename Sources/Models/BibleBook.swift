import Foundation

// MARK: - Testament

enum Testament: String, CaseIterable, Codable, Sendable {
    case oldTestament = "Old Testament"
    case newTestament = "New Testament"
}

// MARK: - BibleBook

struct BibleBook: Identifiable, Hashable, Codable, Sendable {
    let id: Int // canonical order index (1-66)
    let fullName: String
    let abbreviation: String // LSM Recovery Version API abbreviation
    let chapterCount: Int
    let testament: Testament

    var isSingleChapter: Bool { chapterCount == 1 }

    init(id: Int, fullName: String, abbreviation: String, chapterCount: Int, testament: Testament) {
        self.id = id
        self.fullName = fullName
        self.abbreviation = abbreviation
        self.chapterCount = chapterCount
        self.testament = testament
    }
}

// MARK: - All 66 Books

extension BibleBook {
    static let allBooks: [BibleBook] = oldTestamentBooks + newTestamentBooks

    static let oldTestamentBooks: [BibleBook] = [
        BibleBook(id: 1, fullName: "Genesis", abbreviation: "Gen.", chapterCount: 50, testament: .oldTestament),
        BibleBook(id: 2, fullName: "Exodus", abbreviation: "Exo.", chapterCount: 40, testament: .oldTestament),
        BibleBook(id: 3, fullName: "Leviticus", abbreviation: "Lev.", chapterCount: 27, testament: .oldTestament),
        BibleBook(id: 4, fullName: "Numbers", abbreviation: "Num.", chapterCount: 36, testament: .oldTestament),
        BibleBook(id: 5, fullName: "Deuteronomy", abbreviation: "Deut.", chapterCount: 34, testament: .oldTestament),
        BibleBook(id: 6, fullName: "Joshua", abbreviation: "Josh.", chapterCount: 24, testament: .oldTestament),
        BibleBook(id: 7, fullName: "Judges", abbreviation: "Judg.", chapterCount: 21, testament: .oldTestament),
        BibleBook(id: 8, fullName: "Ruth", abbreviation: "Ruth", chapterCount: 4, testament: .oldTestament),
        BibleBook(id: 9, fullName: "1 Samuel", abbreviation: "1 Sam.", chapterCount: 31, testament: .oldTestament),
        BibleBook(id: 10, fullName: "2 Samuel", abbreviation: "2 Sam.", chapterCount: 24, testament: .oldTestament),
        BibleBook(id: 11, fullName: "1 Kings", abbreviation: "1 Kings", chapterCount: 22, testament: .oldTestament),
        BibleBook(id: 12, fullName: "2 Kings", abbreviation: "2 Kings", chapterCount: 25, testament: .oldTestament),
        BibleBook(id: 13, fullName: "1 Chronicles", abbreviation: "1 Chron.", chapterCount: 29, testament: .oldTestament),
        BibleBook(id: 14, fullName: "2 Chronicles", abbreviation: "2 Chron.", chapterCount: 36, testament: .oldTestament),
        BibleBook(id: 15, fullName: "Ezra", abbreviation: "Ezra", chapterCount: 10, testament: .oldTestament),
        BibleBook(id: 16, fullName: "Nehemiah", abbreviation: "Neh.", chapterCount: 13, testament: .oldTestament),
        BibleBook(id: 17, fullName: "Esther", abbreviation: "Esth.", chapterCount: 10, testament: .oldTestament),
        BibleBook(id: 18, fullName: "Job", abbreviation: "Job", chapterCount: 42, testament: .oldTestament),
        BibleBook(id: 19, fullName: "Psalms", abbreviation: "Psa.", chapterCount: 150, testament: .oldTestament),
        BibleBook(id: 20, fullName: "Proverbs", abbreviation: "Prov.", chapterCount: 31, testament: .oldTestament),
        BibleBook(id: 21, fullName: "Ecclesiastes", abbreviation: "Eccl.", chapterCount: 12, testament: .oldTestament),
        BibleBook(id: 22, fullName: "Song of Solomon", abbreviation: "S.S.", chapterCount: 8, testament: .oldTestament),
        BibleBook(id: 23, fullName: "Isaiah", abbreviation: "Isa.", chapterCount: 66, testament: .oldTestament),
        BibleBook(id: 24, fullName: "Jeremiah", abbreviation: "Jer.", chapterCount: 52, testament: .oldTestament),
        BibleBook(id: 25, fullName: "Lamentations", abbreviation: "Lam.", chapterCount: 5, testament: .oldTestament),
        BibleBook(id: 26, fullName: "Ezekiel", abbreviation: "Ezek.", chapterCount: 48, testament: .oldTestament),
        BibleBook(id: 27, fullName: "Daniel", abbreviation: "Dan.", chapterCount: 12, testament: .oldTestament),
        BibleBook(id: 28, fullName: "Hosea", abbreviation: "Hosea", chapterCount: 14, testament: .oldTestament),
        BibleBook(id: 29, fullName: "Joel", abbreviation: "Joel", chapterCount: 3, testament: .oldTestament),
        BibleBook(id: 30, fullName: "Amos", abbreviation: "Amos", chapterCount: 9, testament: .oldTestament),
        BibleBook(id: 31, fullName: "Obadiah", abbreviation: "Oba.", chapterCount: 1, testament: .oldTestament),
        BibleBook(id: 32, fullName: "Jonah", abbreviation: "Jonah", chapterCount: 4, testament: .oldTestament),
        BibleBook(id: 33, fullName: "Micah", abbreviation: "Micah", chapterCount: 7, testament: .oldTestament),
        BibleBook(id: 34, fullName: "Nahum", abbreviation: "Nahum", chapterCount: 3, testament: .oldTestament),
        BibleBook(id: 35, fullName: "Habakkuk", abbreviation: "Hab.", chapterCount: 3, testament: .oldTestament),
        BibleBook(id: 36, fullName: "Zephaniah", abbreviation: "Zeph.", chapterCount: 3, testament: .oldTestament),
        BibleBook(id: 37, fullName: "Haggai", abbreviation: "Hag.", chapterCount: 2, testament: .oldTestament),
        BibleBook(id: 38, fullName: "Zechariah", abbreviation: "Zech.", chapterCount: 14, testament: .oldTestament),
        BibleBook(id: 39, fullName: "Malachi", abbreviation: "Mal.", chapterCount: 4, testament: .oldTestament),
    ]

    static let newTestamentBooks: [BibleBook] = [
        BibleBook(id: 40, fullName: "Matthew", abbreviation: "Matt.", chapterCount: 28, testament: .newTestament),
        BibleBook(id: 41, fullName: "Mark", abbreviation: "Mark", chapterCount: 16, testament: .newTestament),
        BibleBook(id: 42, fullName: "Luke", abbreviation: "Luke", chapterCount: 24, testament: .newTestament),
        BibleBook(id: 43, fullName: "John", abbreviation: "John", chapterCount: 21, testament: .newTestament),
        BibleBook(id: 44, fullName: "Acts", abbreviation: "Acts", chapterCount: 28, testament: .newTestament),
        BibleBook(id: 45, fullName: "Romans", abbreviation: "Rom.", chapterCount: 16, testament: .newTestament),
        BibleBook(id: 46, fullName: "1 Corinthians", abbreviation: "1 Cor.", chapterCount: 16, testament: .newTestament),
        BibleBook(id: 47, fullName: "2 Corinthians", abbreviation: "2 Cor.", chapterCount: 13, testament: .newTestament),
        BibleBook(id: 48, fullName: "Galatians", abbreviation: "Gal.", chapterCount: 6, testament: .newTestament),
        BibleBook(id: 49, fullName: "Ephesians", abbreviation: "Eph.", chapterCount: 6, testament: .newTestament),
        BibleBook(id: 50, fullName: "Philippians", abbreviation: "Phil.", chapterCount: 4, testament: .newTestament),
        BibleBook(id: 51, fullName: "Colossians", abbreviation: "Col.", chapterCount: 4, testament: .newTestament),
        BibleBook(id: 52, fullName: "1 Thessalonians", abbreviation: "1 Thes.", chapterCount: 5, testament: .newTestament),
        BibleBook(id: 53, fullName: "2 Thessalonians", abbreviation: "2 Thes.", chapterCount: 3, testament: .newTestament),
        BibleBook(id: 54, fullName: "1 Timothy", abbreviation: "1 Tim.", chapterCount: 6, testament: .newTestament),
        BibleBook(id: 55, fullName: "2 Timothy", abbreviation: "2 Tim.", chapterCount: 4, testament: .newTestament),
        BibleBook(id: 56, fullName: "Titus", abbreviation: "Titus", chapterCount: 3, testament: .newTestament),
        BibleBook(id: 57, fullName: "Philemon", abbreviation: "Philem.", chapterCount: 1, testament: .newTestament),
        BibleBook(id: 58, fullName: "Hebrews", abbreviation: "Heb.", chapterCount: 13, testament: .newTestament),
        BibleBook(id: 59, fullName: "James", abbreviation: "James", chapterCount: 5, testament: .newTestament),
        BibleBook(id: 60, fullName: "1 Peter", abbreviation: "1 Pet.", chapterCount: 5, testament: .newTestament),
        BibleBook(id: 61, fullName: "2 Peter", abbreviation: "2 Pet.", chapterCount: 3, testament: .newTestament),
        BibleBook(id: 62, fullName: "1 John", abbreviation: "1 John", chapterCount: 5, testament: .newTestament),
        BibleBook(id: 63, fullName: "2 John", abbreviation: "2 John", chapterCount: 1, testament: .newTestament),
        BibleBook(id: 64, fullName: "3 John", abbreviation: "3 John", chapterCount: 1, testament: .newTestament),
        BibleBook(id: 65, fullName: "Jude", abbreviation: "Jude", chapterCount: 1, testament: .newTestament),
        BibleBook(id: 66, fullName: "Revelation", abbreviation: "Rev.", chapterCount: 22, testament: .newTestament),
    ]
}

// MARK: - Lookup Helpers

extension BibleBook {
    /// Find a book by its LSM abbreviation (e.g. "Gen.", "Matt.").
    static func findByAbbreviation(_ abbr: String) -> BibleBook? {
        allBooks.first { $0.abbreviation == abbr }
    }

    /// Find a book by its full name (case-insensitive).
    static func findByFullName(_ name: String) -> BibleBook? {
        allBooks.first { $0.fullName.lowercased() == name.lowercased() }
    }

    /// Find a book by its canonical order (1-66).
    static func findById(_ id: Int) -> BibleBook? {
        guard (1...66).contains(id) else { return nil }
        return allBooks.first { $0.id == id }
    }

    /// All single-chapter books.
    static var singleChapterBooks: [BibleBook] {
        allBooks.filter(\.isSingleChapter)
    }

    /// Total number of books in a testament.
    static func count(for testament: Testament) -> Int {
        allBooks.filter { $0.testament == testament }.count
    }
}
