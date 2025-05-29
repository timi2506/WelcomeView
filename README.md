# WelcomeView

## Installation

### Using Xcode's built-in Package Manager

Go to File \> Add Package Dependencies...

then, in the Search-Bar enter:

`https://github.com/timi2506/WelcomeView.git`

and press "Add Package" and make sure to link it to your target.

## Usage

The `WelcomeView` package provides a SwiftUI-based welcome screen experience, comprised of a `WelcomeWindowScene` for window management and the `WelcomeView` itself to display application details, custom actions, and recent files.

### Components

#### `WelcomeWindowScene` *Scene*

This is the `Scene` that wraps your `WelcomeView` and presents it as a plain-styled window, ideal for initial app launch or welcome screens.

```swift
@available(macOS 15.0, *)
public struct WelcomeWindowScene: Scene {
    public init(id: String? = nil, content: WelcomeView)
}
```

  - **id** *Optional*
      - A unique identifier for the window scene, defaults to an empty string.
  - **content** *Required*
      - The `WelcomeView` instance to be displayed within the window.

#### `WelcomeView` *View*

The main view for the welcome screen, featuring your app icon, version, a menu for actions, and a section for recent files.

```swift
public struct WelcomeView: View {
    public init(
        titleText: Binding<String>,
        menu: Binding<WelcomeMenu>,
        emptyMessage: String = "No Recent Files",
        recents: Binding<[RecentFileView]>
    )
}
```

  - **titleText** *Required*
      - A `Binding<String>` for the main title displayed on the welcome screen (e.g., "Welcome to My App\!").
  - **menu** *Required*
      - A `Binding<WelcomeMenu>` that contains the custom menu buttons for your welcome screen.
  - **emptyMessage** *Optional*
      - A `String` displayed when there are no recent files, defaults to "No Recent Files".
  - **recents** *Required*
      - A `Binding<[RecentFileView]>` to display a list of recent files.

#### `WelcomeMenu` *View*

A container view that arranges `WelcomeMenuButton` instances in a vertical stack. It uses SwiftUI's `@ViewBuilder` for flexible content.

```swift
public struct WelcomeMenu: View {
    public init(@ViewBuilder content: () -> WelcomeMenuButton)
    public init(@ViewBuilder content: () -> TupleView<(WelcomeMenuButton, WelcomeMenuButton)>)
    public init(@ViewBuilder content: () -> TupleView<(WelcomeMenuButton, WelcomeMenuButton, WelcomeMenuButton)>)
    // Supports up to 3 buttons directly, more can be added via array
}
```

#### `WelcomeMenuButton` *View*

A customizable button designed for use within a `WelcomeMenu`.

```swift
public struct WelcomeMenuButton: View {
    public init(title: String, image: Image, action: @escaping () -> Void)
}
```

  - **title** *Required*
      - The text label for the button.
  - **image** *Required*
      - A SwiftUI `Image` (e.g., a system icon) to display next to the title.
  - **action** *Required*
      - A closure to execute when the button is tapped.

#### `RecentFileView` *View*

A view to represent an individual recent file, displaying its name, path, and file type icon. Tapping it can trigger an action to open the file.

```swift
public struct RecentFileView: View {
    public init(fileURL: URL, action: @escaping (URL) -> Void, resetSelection: Binding<Bool>)
}
```

  - **fileURL** *Required*
      - The `URL` of the recent file.
  - **action** *Required*
      - A closure that takes the file's `URL` as a parameter, executed when the file is tapped.
  - **resetSelection** *Required*
      - A `Binding<Bool>` used internally to manage selection state when other recent files are tapped.

-----

***Optional*** means this value can be safely omitted

***Required*** means you NEED to define this value and it can't be nil

### Example Usage

```swift
import SwiftUI
import WelcomeView

@main
struct MyApp: App {
    @State private var welcomeTitle = "Welcome to MyApp!"
    @State private var recentDocuments: [RecentFileView] = [
        RecentFileView(fileURL: URL(fileURLWithPath: "/path/to/document1.txt")) { url in
            print("Opening \(url.lastPathComponent)")
            // Add your file opening logic here
        },
        RecentFileView(fileURL: URL(fileURLWithPath: "/path/to/another_project.md")) { url in
            print("Opening \(url.lastPathComponent)")
            // Add your file opening logic here
        }
    ]

    var body: some Scene {
        // Your main application window(s)
        WindowGroup {
            ContentView()
        }

        // The WelcomeWindowScene for your welcome screen
        // You would typically control its presentation based on app logic (e.g., first launch)
        WelcomeWindowScene(id: "appWelcome") {
            WelcomeView(
                titleText: $welcomeTitle,
                menu: .constant(
                    WelcomeMenu {
                        WelcomeMenuButton(title: "Create New", image: Image(systemName: "plus.document.fill")) {
                            print("Create New Document")
                        }
                        WelcomeMenuButton(title: "Open...", image: Image(systemName: "folder.fill.badge.plus")) {
                            print("Open Existing Document")
                        }
                        WelcomeMenuButton(title: "Settings", image: Image(systemName: "gearshape.fill")) {
                            print("Open Settings")
                        }
                    }
                ),
                recents: $recentDocuments
            )
        }
    }
}
```

## Issues or Questions

If you have any issues or questions, feel free to open an [issue](https://www.google.com/search?q=https://github.com/timi2506/WelcomeView/issues/new/choose).

## Requirements

  - macOS 14+
