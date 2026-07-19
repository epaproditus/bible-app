import SwiftUI

struct ContentView: View {
    @State private var detent: SplitDetent = .footnotesExpanded

    var body: some View {
        VerticalSplit(
            detent: $detent,
            topTitle: "Scripture",
            bottomTitle: "Footnotes"
        ) {
            // Top pane — Scripture text
            scripturePane
        } bottomView: {
            // Bottom pane — Footnotes / commentary
            footnotesPane
        }
    }

    // MARK: - Scripture Pane

    private var scripturePane: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Genesis 1:1-5")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("""
                1 In the beginning God created the heavens and the earth.

                2 And the earth was waste and emptiness, and darkness was on the surface of the deep, and the Spirit of God was brooding upon the surface of the waters.

                3 And God said, Let there be light; and there was light.

                4 And God saw that the light was good, and God separated the light from the darkness.

                5 And God called the light Day, and the darkness He called Night. And there was evening and there was morning, one day.
                """)
                .font(.body)
                .lineSpacing(6)

                Spacer()
            }
            .padding()
        }
    }

    // MARK: - Footnotes Pane

    private var footnotesPane: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Footnotes")
                    .font(.headline)
                    .fontWeight(.semibold)

                Group {
                    footnoteView(
                        verse: 1,
                        text: "Or, created. The Hebrew word bara (create) implies to create out of nothing; hence it denotes the initiation of the original creation of the heavens and the earth."
                    )
                    footnoteView(
                        verse: 2,
                        text: "The waste and emptiness resulting from God's judgment on the original creation that had become corrupted by Satan's rebellion (Isa. 45:18; cf. Jer. 4:23-26)."
                    )
                    footnoteView(
                        verse: 3,
                        text: "The light here refers to the light of the first day of God's restoration, which is a type of the light of life in the New Creation (2 Cor. 4:6)."
                    )
                }

                Spacer()
            }
            .padding()
        }
    }

    private func footnoteView(verse: Int, text: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("v\(verse)")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.primary)
            Divider()
        }
    }
}

#Preview {
    ContentView()
}
