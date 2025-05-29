import SwiftUI
import UniformTypeIdentifiers

@available(macOS 15.0, *)
public struct WelcomeWindowScene: Scene {
    public let id: String?
    public let content: WelcomeView
    
    public init(id: String? = nil, content: WelcomeView) {
        self.content = content
        self.id = id
    }
    
    public var body: some Scene {
        WindowGroup(id: id ?? "") {
            content
                .padding(5)
                .background(.thickMaterial)
                .background(
                    WindowAccessor(callback: { window in
                        window?.isMovableByWindowBackground = true
                    })
                )
                .cornerRadius(10)
        }
        .windowStyle(.plain)
    }
}

public struct WindowAccessor: NSViewRepresentable {
    public var callback: (NSWindow?) -> Void

    public init(callback: @escaping (NSWindow?) -> Void) {
        self.callback = callback
    }

    public func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            self.callback(view.window)
        }
        return view
    }

    public func updateNSView(_ nsView: NSView, context: Context) {}
}

public struct WelcomeView: View {
    @Environment(\.dismissWindow) private var dismissWindow
    @Binding public var titleText: String
    @Binding public var menu: WelcomeMenu
    public var emptyMessage = "No Recent Files"
    @Binding public var recents: [RecentFileView]
    @State private var resetSelection = false
    
    public init(
        titleText: Binding<String>,
        menu: Binding<WelcomeMenu>,
        emptyMessage: String = "No Recent Files",
        recents: Binding<[RecentFileView]>
    ) {
        self._titleText = titleText
        self._menu = menu
        self.emptyMessage = emptyMessage
        self._recents = recents
    }

    public var body: some View {
        ZStack {
            HStack(alignment: .top, spacing: 0.0) {
                VStack(alignment: .center, spacing: 0.0) {
                    Image(nsImage: NSApp.applicationIconImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 140.0, height: 140.0)
                        .background {
                            Image(nsImage: NSApp.applicationIconImage)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 140.0, height: 140.0)
                                .blur(radius: 50)
                        }
                    
                    Spacer().frame(height: 3.0)
                    
                    Text(titleText)
                        .font(.system(size: 36.0))
                        .bold()
                    
                    Spacer().frame(height: 7.0)
                    
                    Text("Version \(getCurrentAppVersion())")
                        .font(.system(size: 13.0))
                        .fontWeight(.light)
                        .foregroundColor(.gray)
                    
                    Spacer()
                        .frame(minHeight: max(24.0, min(6.0, (CGFloat(1) - 2.0) * 6.0)))
                    
                    VStack(alignment: .leading, spacing: 5) {
                        menu
                    }
                    .padding(.horizontal, 35)
                }
                .frame(width: 414.0)
                .padding(40.0)
                VStack {
                    if recents.isEmpty {
                        VStack {
                            Spacer()
                            Text(emptyMessage)
                                .bold()
                                .foregroundStyle(.gray)
                            Spacer()
                        }
                    } else {
                        ScrollView(.vertical, showsIndicators: false) {
                            VStack(alignment: .leading, spacing: 0) {
                                ForEach(recents, id: \.self.fileURL) { view in
                                    view
                                }
                                Spacer()
                            }
                            .padding(5)
                        }
                    }
                }
                .frame(width: 250)
                .background(.gray.opacity(0.10))
                .onTapGesture {
                    resetSelection = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        resetSelection = false
                    }
                }
                .cornerRadius(7.5)
            }
            Button(action: {
                dismissWindow.callAsFunction()
            }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.gray.opacity(0.50))
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity, maxHeight: 450, alignment: .topLeading)
            .padding(5)
        }
        .frame(width: 745, height: 450.0)
    }
    
    private func getCurrentAppVersion() -> String {
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        return appVersion
    }
}

public struct WelcomeMenuButton: View {
    public let title: String
    public let image: Image
    public let action: () -> Void

    public init(title: String, image: Image, action: @escaping () -> Void) {
        self.title = title
        self.image = image
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack {
                image
                    .foregroundStyle(.gray)
                    .font(.system(size: 17.5, weight: .medium))
                    .frame(width: 25)
                Text(title)
                    .font(.system(size: 12.5, weight: .semibold))
                Spacer()
            }
            .padding(7.5)
            .background(.gray.opacity(0.10))
            .cornerRadius(5)
        }
        .buttonStyle(.plain)
    }
}

public struct WelcomeMenu: View {
    private let buttons: [WelcomeMenuButton]

    public init(@ViewBuilder content: () -> WelcomeMenuButton) {
        self.buttons = [content()]
    }

    public init(@ViewBuilder content: () -> TupleView<(WelcomeMenuButton, WelcomeMenuButton)>) {
        let tuple = content().value
        self.buttons = [tuple.0, tuple.1]
    }

    public init(@ViewBuilder content: () -> TupleView<(WelcomeMenuButton, WelcomeMenuButton, WelcomeMenuButton)>) {
        let tuple = content().value
        self.buttons = [tuple.0, tuple.1, tuple.2]
    }

    public var body: some View {
        VStack(spacing: 8) {
            ForEach(0..<buttons.count, id: \.self) { index in
                buttons[index]
            }
        }
    }
}

public struct RecentFileView: View {
    public init(fileURL: URL, action: @escaping (URL) -> Void, resetSelection: Binding<Bool>) {
        self.fileURL = fileURL
        self.filePath = fileURL.deletingLastPathComponent().path
        if !fileURL.pathExtension.isEmpty {
            self.fileName = fileURL.lastPathComponent.replacingOccurrences(of: ".\(fileURL.pathExtension)", with: "")
        } else {
            self.fileName = fileURL.lastPathComponent
        }
        self.openAction = action
        self._resetSelection = resetSelection
        self.fileExtension = fileURL.pathExtension
    }
    
    public let fileURL: URL
    public let filePath: String
    public let fileName: String
    public let fileExtension: String
    public var openAction: (URL) -> Void
    @State private var selected = false
    @Binding public var resetSelection: Bool
    @State private var immuneToReset = false
    @State private var pressedBefore = false

    public var body: some View {
        if fileURL.isFileURL {
            HStack {
                Image(nsImage: NSWorkspace.shared.icon(for: UTType(filenameExtension: fileExtension) ?? .data))
                    .font(.system(size: 25))
                VStack(alignment: .leading) {
                    Text(fileName)
                        .bold()
                        .lineLimit(1)
                    
                    Text(filePath)
                        .font(.caption)
                        .foregroundStyle(.gray)
                        .lineLimit(1)
                }
                Spacer()
            }
            .padding(7.5)
            .background(.tint.secondary.opacity(selected ? 1 : 0))
            .cornerRadius(5)
            .contentShape(.rect)
            .onTapGesture {
                if pressedBefore {
                    openAction(fileURL)
                    pressedBefore = false
                } else {
                    pressedBefore = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
                        pressedBefore = false
                    }
                }
                resetSelection = true
                immuneToReset = true
                selected = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    resetSelection = false
                    immuneToReset = false
                }
            }
            .onChange(of: resetSelection) { bool in
                if !immuneToReset && bool {
                    selected = false
                }
            }
        }
    }
}

// MARK: - Helper Extensions

public extension Image {
    func systemImage(_ systemName: String) -> Image {
        Image(systemName: systemName)
    }
}

public extension String {
    func removing(_ string: String) -> String {
        self.replacingOccurrences(of: string, with: "")
    }
}
