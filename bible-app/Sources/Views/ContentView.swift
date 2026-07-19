import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "book.closed.fill")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Bible App")
                .font(.title)
                .fontWeight(.semibold)
            Text("Living Stream Recovery Version")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
