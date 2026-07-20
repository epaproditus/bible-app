import SwiftUI

/// Root Bible view: book list sectioned by Old / New Testament.
struct BibleListView: View {
    @State private var navigationPath = NavigationPath()

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ScrollView {
                VStack(spacing: 0) {
                    header

                    testamentSection(title: "Old Testament", books: BibleDataService.oldTestament)
                    testamentSection(title: "New Testament", books: BibleDataService.newTestament)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Bible")
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(for: Book.self) { book in
                if book.chapters == 1 {
                    BibleReadingView(book: book, chapter: 1)
                } else {
                    ChapterGridView(book: book, chapters: BibleDataService.chapters(for: book))
                }
            }
            .navigationDestination(for: BibleDestination.self) { dest in
                switch dest {
                case .chapterGrid(let book):
                    ChapterGridView(book: book, chapters: BibleDataService.chapters(for: book))
                case .reading(let book, let chapter):
                    BibleReadingView(book: book, chapter: chapter)
                }
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 4) {
            Text("Recovery Version")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
            Text("66 books")
                .font(.system(size: 12, weight: .regular, design: .rounded))
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }

    // MARK: - Testament Section

    private func testamentSection(title: String, books: [Book]) -> some View {
        VStack(spacing: 0) {
            sectionLabel(title.uppercased())

            LazyVStack(spacing: 0) {
                ForEach(Array(books.enumerated()), id: \.element.code) { index, book in
                    NavigationLink(value: book) {
                        BookRow(book: book)
                    }
                    .buttonStyle(.plain)

                    if index < books.count - 1 {
                        Divider()
                            .padding(.leading, 66)
                    }
                }
            }
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold, design: .rounded))
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.bottom, 8)
    }
}

// MARK: - Book Row

struct BookRow: View {
    let book: Book

    var body: some View {
        HStack(spacing: 14) {
            // Book code badge
            Text(book.code)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 40, height: 28)
                .background(book.testament == 0 ? Color.indigo : Color.teal)
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))

            VStack(alignment: .leading, spacing: 1) {
                Text(book.name)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(.primary)
                Text("\(book.chapters) \(book.chapters == 1 ? "chapter" : "chapters")")
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }
}

#Preview {
    BibleListView()
}
