import SwiftUI
import UniformTypeIdentifiers
import Combine

public struct WelcomeWindowView: View {
    public init(content: WelcomeView) {
        self.content = content
    }
    public let content: WelcomeView
    
    public var body: some View {
        content
            .padding(7.5)
            .background(.thickMaterial)
            .onWindowAppear { window in
                window?.isMovableByWindowBackground = true
                window?.backgroundColor = .clear
                window?.styleMask = .borderless
            }
            .cornerRadius(25)
    }
}

public struct WelcomeView: View {
    public var titleText: String
    public var menu: WelcomeMenu
    public var emptyMessage = "No Recent Files"
    public let recentFileProvider: RecentFileProvider
    @State private var recents: [RecentFile] = []
    @State private var resetSelection = false
    @State private var selectedFile: URL?
    
    public init(titleText: String, menu: WelcomeMenu, emptyMessage: String = "No Recent Files", recentFileProvider: RecentFileProvider = .default) {
        self.titleText = titleText
        self.menu = menu
        self.emptyMessage = emptyMessage
        self.recentFileProvider = recentFileProvider
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
                        List(selection: $selectedFile) {
                            ForEach(recents) { file in
                                makeRecentView(for: file)
                                    .tag(file.url)
                                    .listRowSeparator(.hidden)
                            }
                        }
                        .listStyle(.inset)
                        .refreshable {
                            withAnimation {
                                recents = recentFileProvider.provideRecentFiles()
                            }
                        }
                        .scrollIndicators(.never)
                    }
                }
                .frame(width: 250)
                .background(.gray.opacity(0.25))
                .onTapGesture {
                    resetSelection = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        resetSelection = false
                    }
                }
                .cornerRadius(20)
            }
            CloseWindowButton()
            .frame(maxWidth: .infinity, maxHeight: 450, alignment: .topLeading)
            .padding(5)
        }
        .frame(width: 745, height: 450.0)
        .onAppear {
            withAnimation {
                recents = recentFileProvider.provideRecentFiles()
            }
        }
    }
    
    private func getCurrentAppVersion() -> String {
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        return appVersion
    }
    private func makeRecentView(for file: RecentFile) -> some View {
        HStack {
            Image(nsImage: recentFileProvider.makeIcon(for: file))
                .font(.system(size: 25))
            VStack(alignment: .leading) {
                Text(recentFileProvider.makeTitle(for: file))
                    .bold()
                    .lineLimit(1)
                
                Text(recentFileProvider.makeSubtitle(for: file))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer()
        }
        .padding(.vertical, 5)
        .contentShape(.rect)
        .simultaneousGesture(
            TapGesture()
                .onEnded { _ in
                    recentFileProvider.openFile(file)
                },
            isEnabled: selectedFile == file.url
        )
        .overlay {
            if selectedFile == file.url {
                Button("") {
                    recentFileProvider.openFile(file)
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.defaultAction)
                .offset(x: -100)
            }
        }
    }
}

struct CloseWindowButton: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let containerView = NSView()
        
        let closeButton = Button(action: { [weak containerView] in
            containerView?.window?.close()
        }) {
            Image(systemName: "xmark.circle.fill")
                .foregroundStyle(.secondary)
        }
        .buttonStyle(.plain)

        let hostingView = NSHostingView(rootView: closeButton)
        hostingView.translatesAutoresizingMaskIntoConstraints = false
        
        containerView.addSubview(hostingView)
        
        NSLayoutConstraint.activate([
            hostingView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            hostingView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            hostingView.topAnchor.constraint(equalTo: containerView.topAnchor),
            hostingView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
        
        return containerView
    }
    
    func updateNSView(_ nsView: NSView, context: Context) { }
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
            .background(.gray.opacity(0.25))
            .clipShape(.capsule)
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

@MainActor
public protocol RecentFileProvider {
    func provideRecentFiles() -> [RecentFile]
    func openFile(_ file: RecentFile)
    func makeTitle(for file: RecentFile) -> String
    func makeSubtitle(for file: RecentFile) -> String
    func makeIcon(for file: RecentFile) -> NSImage
}

public extension RecentFileProvider where Self == RecentDocumentControllerFileProvider {
    static var `default`: RecentDocumentControllerFileProvider { RecentDocumentControllerFileProvider() }
}

public extension RecentFileProvider {
    func makeTitle(for file: RecentFile) -> String {
        file.customTitle ?? file.url.lastPathComponent
    }
    func makeSubtitle(for file: RecentFile) -> String {
        file.customSubtitle ?? file.url
            .deletingLastPathComponent()
            .path(percentEncoded: false)
            .replacingOccurrences(of: URL.userDirectory.path, with: "~")
    }
    func makeIcon(for file: RecentFile) -> NSImage {
        file.customIcon ?? NSWorkspace.shared.icon(forFile: file.url.path)
    }
}

public struct RecentFile: Hashable, Identifiable {
    public init(customIcon: NSImage? = nil, customTitle: String? = nil, customSubtitle: String? = nil, url: URL) {
        self.customIcon = customIcon
        self.customTitle = customTitle
        self.customSubtitle = customSubtitle
        self.url = url
    }
    public let id = UUID()

    public let customIcon: NSImage?
    public let customTitle: String?
    public let customSubtitle: String?
    public let url: URL
}

@MainActor
open class RecentDocumentControllerFileProvider: RecentFileProvider {
    public init() {
        
    }
    open func openFile(_ file: RecentFile) {
        NSWorkspace.shared.open(file.url)
    }
    
    open func provideRecentFiles() -> [RecentFile] {
        NSDocumentController.shared.recentDocumentURLs.map {
            RecentFile(url: $0)
        }
    }
}

fileprivate extension View {
    func onWindowAppear(_ callback: @escaping (NSWindow?) -> Void) -> some View {
        background(WindowAccessor(callback: callback))
    }
}

fileprivate struct WindowAccessor: NSViewRepresentable {
    var callback: (NSWindow?) -> Void

    func makeNSView(context: Context) -> NSView {
        let v = NSView()
        DispatchQueue.main.async {
            self.callback(v.window)
        }
        return v
    }

    func updateNSView(_ nsView: NSView, context: Context) { }
}
