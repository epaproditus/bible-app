import Foundation

// MARK: - Book Catalogue

/// A single book of the Bible with its key metadata.
/// Codes match the per-book JSON file names (e.g. "Gen", "Exo").
struct Book: Identifiable, Hashable, Sendable {
    var id: String { code }
    let code: String
    let name: String
    let chapters: Int
    /// 0 = Old Testament, 1 = New Testament
    let testament: Int
    let order: Int

    var testamentName: String { testament == 0 ? "Old Testament" : "New Testament" }

    static func == (lhs: Book, rhs: Book) -> Bool { lhs.code == rhs.code }
    func hash(into hasher: inout Hasher) { hasher.combine(code) }
}

// MARK: - Verse / Chapter display models

/// A single Bible verse with its text and inline footnote markers.
struct BibleVerse: Identifiable, Hashable, Sendable {
    let id: String  // e.g. "1_1" (chapter_verse)
    let bookCode: String
    let chapter: Int
    let verse: Int
    let text: String
    var footnoteMarkers: [FootnoteMarker] = []

    var displayReference: String { "\(bookCode) \(chapter):\(verse)" }
}

/// A footnote marker embedded in verse text.
struct FootnoteMarker: Hashable, Sendable {
    let marker: String
    let footnoteID: String  // e.g. "n1_1x1a"
}

/// A footnote with its content and cross-references.
struct BibleFootnote: Identifiable, Hashable, Sendable {
    let id: String  // e.g. "n1_1x1a"
    let bookCode: String
    let chapter: Int
    let verse: Int
    let marker: String
    let text: String
    var crossReferences: [String] = []
}

// MARK: - Navigation destinations

enum BibleDestination: Hashable {
    case chapterGrid(book: Book)
    case reading(book: Book, chapter: Int)
}
