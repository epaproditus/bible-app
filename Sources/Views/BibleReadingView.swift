import SwiftUI

/// Verse reading view with VerticalSplit layout.
struct BibleReadingView: View {
    let book: Book
    let chapter: Int

    @State private var verses: [BibleVerse] = []
    @State private var selectedFootnote: BibleFootnote?
    @State private var expandedVerse: Int?
    @State private var isLoading = true
    @State private var splitDetent: SplitDetent = .footnotesExpanded

    var body: some View {
        VerticalSplit(
            detent: $splitDetent,
            topTitle: book.name,
            bottomTitle: "Footnotes"
        ) {
            VerseScrollView(
                book: book,
                chapter: chapter,
                verses: verses,
                isLoading: isLoading,
                copyright: BibleAPIService.copyright(for: book.code),
                expandedVerse: $expandedVerse,
                selectedFootnote: $selectedFootnote
            )
        } bottomView: {
            if let fn = selectedFootnote {
                FootnotePanel(
                    footnote: fn,
                    onDismiss: {
                        withAnimation(.spring(response: 0.35)) {
                            selectedFootnote = nil
                        }
                    }
                )
                .transition(.opacity)
            } else {
                FootnotesPlaceholder()
            }
        }
        .background(Color(.systemBackground))
        .navigationTitle(book.name)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            isLoading = true
            BibleAPIService.preload(bookCode: book.code)
            verses = BibleAPIService.verses(for: book.code, chapter: chapter)
            isLoading = false
        }
    }
}

// MARK: - Verse Scroll View

private struct VerseScrollView: View {
    let book: Book
    let chapter: Int
    let verses: [BibleVerse]
    let isLoading: Bool
    let copyright: String
    @Binding var expandedVerse: Int?
    @Binding var selectedFootnote: BibleFootnote?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Chapter header
                Text("\(book.name) \(chapter)")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 16)

                if isLoading {
                    VStack(spacing: 12) {
                        ForEach(0..<5, id: \.self) { _ in
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.gray.opacity(0.15))
                                .frame(height: 14)
                        }
                    }
                    .padding(.horizontal, 20)
                } else if verses.isEmpty {
                    Text("No verses found for \(book.name) \(chapter).")
                        .font(.system(size: 15, weight: .regular, design: .rounded))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                } else {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(verses, id: \.id) { verse in
                            VerseRow(
                                verse: verse,
                                bookCode: book.code,
                                chapter: chapter,
                                isExpanded: expandedVerse == verse.verse,
                                onToggle: {
                                    withAnimation(.spring(response: 0.3)) {
                                        if expandedVerse == verse.verse {
                                            expandedVerse = nil
                                        } else {
                                            expandedVerse = verse.verse
                                        }
                                    }
                                },
                                onFootnoteTapped: { fn in
                                    selectedFootnote = fn
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)

                    // Copyright footer
                    Text(copyright)
                        .font(.system(size: 10, weight: .regular, design: .rounded))
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 24)
                }

                Spacer()
            }
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Verse Row

private struct VerseRow: View {
    let verse: BibleVerse
    let bookCode: String
    let chapter: Int
    let isExpanded: Bool
    let onToggle: () -> Void
    let onFootnoteTapped: (BibleFootnote) -> Void

    @State private var verseFootnotes: [BibleFootnote] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Verse text with inline footnote markers
            HStack(alignment: .top, spacing: 8) {
                Text("\(verse.verse)")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 24, alignment: .trailing)

                verseTextWithMarkers
                    .font(.system(size: 15, weight: .regular, design: .rounded))
                    .foregroundStyle(.primary)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
                    .textSelection(.enabled)
            }
            .padding(.vertical, 6)

            // Footnote preview cards
            if isExpanded && !verseFootnotes.isEmpty {
                VStack(spacing: 8) {
                    ForEach(verseFootnotes, id: \.id) { fn in
                        FootnotePreviewCard(
                            footnote: fn,
                            onTap: { onFootnoteTapped(fn) }
                        )
                    }
                }
                .padding(.leading, 32)
                .padding(.bottom, 8)
            }

            Divider()
                .padding(.leading, 32)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if !verse.footnoteMarkers.isEmpty {
                loadFootnotes()
                onToggle()
            }
        }
    }

    private var verseTextWithMarkers: Text {
        var result = Text("")
        // Split text by footnote markers like [1a], [2b], etc.
        let pattern = /\[([^\]]+)\]/
        let parts = verse.text.split(omittingEmptySubsequences: false) { character -> Bool in
            character == "[" || character == "]"
        }
        // Actually, we need a different approach. Let's use regex-based splitting.

        var remaining = verse.text
        while let range = remaining.firstMatch(of: pattern) {
            // Text before the marker
            let before = String(remaining[..<range.range.lowerBound])
            if !before.isEmpty {
                result = result + Text(before)
            }
            // The marker text itself (e.g. "1a")
            let markerText = String(range.output.1)
            result = result + Text("[\(markerText)]")
                .foregroundColor(Color.accentColor)
                .font(.system(size: 13, weight: .medium))
                .baselineOffset(4)

            remaining = String(remaining[range.range.upperBound...])
        }
        if !remaining.isEmpty {
            result = result + Text(remaining)
        }
        return result
    }

    private func loadFootnotes() {
        guard verseFootnotes.isEmpty else { return }
        verseFootnotes = BibleAPIService.footnotes(for: bookCode, chapter: chapter, verse: verse.verse)
    }
}

// MARK: - Footnote Preview Card

private struct FootnotePreviewCard: View {
    let footnote: BibleFootnote
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text("\(footnote.marker)")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.accentColor)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.accentColor.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))

                    Text("Tap to expand")
                        .font(.system(size: 11, weight: .regular, design: .rounded))
                        .foregroundStyle(.tertiary)
                }

                Text(footnote.text)
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Footnote Panel

private struct FootnotePanel: View {
    let footnote: BibleFootnote
    let onDismiss: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    Text("Footnote \(footnote.marker)")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(.primary)

                    Spacer()

                    Button(action: onDismiss) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(.tertiary)
                    }
                }

                // Footnote text
                Text(footnote.text)
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundStyle(.primary)
                    .lineSpacing(4)

                // Cross-references
                if !footnote.crossReferences.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Cross-references")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(.secondary)

                        ForEach(footnote.crossReferences, id: \.self) { ref in
                            Text(ref)
                                .font(.system(size: 12, weight: .regular, design: .rounded))
                                .foregroundStyle(Color.accentColor)
                        }
                    }
                    .padding(.top, 8)
                }
            }
            .padding(20)
        }
    }
}

// MARK: - Footnotes Placeholder

private struct FootnotesPlaceholder: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "book.closed")
                .font(.system(size: 24))
                .foregroundStyle(.tertiary)

            Text("Tap a verse with footnotes to see them here.")
                .font(.system(size: 13, weight: .regular, design: .rounded))
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(20)
    }
}

#Preview {
    NavigationStack {
        BibleReadingView(
            book: BibleDataService.book(for: "Gen")!,
            chapter: 1
        )
    }
}
