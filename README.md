# Bible App

A standalone iOS app for reading the Living Stream Recovery Version of the Bible.

## Requirements

- Xcode 15+
- iOS 17+ target
- No third-party dependencies

## Architecture

- **SwiftUI** throughout, using `NavigationStack` and the `App` lifecycle
- **iOS 17+** minimum deployment target for latest SwiftUI APIs
- **LSM Recovery Version API** for verse text (Phase 1)
- **VerticalSplit** layout — draggable two-pane divider (adapted from the Doit app)

## Project Structure

```
bible-app/
├── Sources/
│   ├── App/
│   │   └── BibleApp.swift        # SwiftUI @main entry point
│   └── Views/
│       └── ContentView.swift     # Root view
├── Resources/
│   ├── Assets.xcassets/          # App icons and colors
│   └── Info.plist                # Bundle configuration
├── bible-app.xcodeproj/          # Xcode project
├── .gitignore
└── README.md
```

## Getting Started

1. Open `bible-app/bible-app.xcodeproj` in Xcode 15+
2. Select an iOS 17+ simulator
3. Build and run (Cmd+R)

## License

All Bible text is © Living Stream Ministry. Used with permission.
