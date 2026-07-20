import SwiftUI

/// Chapter selection grid for a specific book.
struct ChapterGridView: View {
    let book: Book
    let chapters: [Int]

    private let columns = [
        GridItem(.adaptive(minimum: 52, maximum: 64), spacing: 10)
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Book header
                Text(book.name)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 4)

                Text("\(book.chapters) chapters")
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)

                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(chapters, id: \.self) { chapter in
                        NavigationLink(value: BibleDestination.reading(book: book, chapter: chapter)) {
                            ChapterCell(number: chapter)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(book.code)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ChapterCell: View {
    let number: Int

    var body: some View {
        Text("\(number)")
            .font(.system(size: 16, weight: .semibold, design: .rounded))
            .foregroundStyle(Color.accentColor)
            .frame(width: 52, height: 52)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color(.separator).opacity(0.3), lineWidth: 1)
            }
    }
}

#Preview {
    NavigationStack {
        ChapterGridView(
            book: BibleDataService.book(for: "Gen")!,
            chapters: BibleDataService.chapters(for: BibleDataService.book(for: "Gen")!)
        )
    }
}
