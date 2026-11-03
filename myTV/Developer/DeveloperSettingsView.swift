import SwiftUI
import DesignTokensKit
import AuthKitUI

struct TVLaunchView: View {
    @State private var authenticationEnabled = AppRuntime.authenticationEnabled
    #if DEBUG
    @State private var showingLaunchSettings = !AppRuntime.isShowcaseLaunch
    @State private var showingSettingsSheet = false
    @State private var configurationID = UUID()
    #endif

    var body: some View {
        #if DEBUG
        Group {
            if showingLaunchSettings {
                NavigationStack {
                    DeveloperSettingsView(buttonTitle: "Open MyTV") {
                        authenticationEnabled = AppRuntime.authenticationEnabled
                        showingLaunchSettings = false
                    }
                }
            } else {
                appContent
                    .id(configurationID)
                    .safeAreaInset(edge: .top) {
                        if AppRuntime.isShowcaseMode {
                            ShowcaseBadgeView {
                                showingSettingsSheet = true
                            }
                        }
                    }
                    .sheet(isPresented: $showingSettingsSheet) {
                        NavigationStack {
                            DeveloperSettingsView(buttonTitle: "Close") {
                                showingSettingsSheet = false
                                authenticationEnabled = AppRuntime.authenticationEnabled
                                configurationID = UUID()
                            }
                        }
                    }
            }
        }
        .background(DebugSettingsPresenter(isLaunchSettingsVisible: showingLaunchSettings) {
            authenticationEnabled = AppRuntime.authenticationEnabled
            configurationID = UUID()
        })
        #else
        appContent
        #endif
    }

    @ViewBuilder private var appContent: some View {
        if authenticationEnabled {
            AppAuthGate(brand: .myTV) { _, _ in
                ChannelListView(viewModel: AppDI.shared.makeChannelListViewModel())
            }
        } else {
            ChannelListView(viewModel: AppDI.shared.makeChannelListViewModel())
        }
    }
}

#if DEBUG
struct ShowcaseBadgeView: View {
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: DesignMetric.p4) {
                Image(systemName: "sparkles")
                    .font(Typography.caption2)
                Text("SHOWCASE DEMO")
                    .font(Typography.caption)
                    .fontWeight(.bold)
                Text("• Tap for Controls")
                    .font(Typography.caption2)
                    .opacity(OpacityToken.p0_5)
            }
            .padding(.horizontal, DesignMetric.p10)
            .padding(.vertical, DesignMetric.p4)
            .background(.ultraThinMaterial)
            .foregroundColor(Color("BrandAction"))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(Color("BrandAction").opacity(OpacityToken.p0_35), lineWidth: DesignMetric.p1)
            )
        }
        .padding(.top, DesignMetric.p4)
        .accessibilityIdentifier("showcase-demo-indicator")
        .accessibilityLabel("Showcase demo mode. Tap to open developer settings.")
    }
}
#endif

#if DEBUG
private extension Notification.Name {
    static let deviceShaken = Notification.Name("MyTV.deviceShaken")
}

// The window remains in the responder chain across navigation, keyboards,
// and presented sheets. Do not take first responder away from text fields.
extension UIWindow {
    open override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        super.motionEnded(motion, with: event)
        guard motion == .motionShake else { return }
        NotificationCenter.default.post(name: .deviceShaken, object: self)
    }
}

private struct DebugSettingsPresenter: UIViewControllerRepresentable {
    var isLaunchSettingsVisible: Bool
    var onApply: () -> Void

    func makeUIViewController(context: Context) -> Presenter {
        Presenter()
    }

    func updateUIViewController(_ controller: Presenter, context: Context) {
        controller.isLaunchSettingsVisible = isLaunchSettingsVisible
        controller.onApply = onApply
    }

    final class Presenter: UIViewController, UIAdaptivePresentationControllerDelegate {
        var isLaunchSettingsVisible = false
        var onApply: () -> Void = {}
        private weak var settingsController: UIViewController?

        override func viewDidLoad() {
            super.viewDidLoad()
            NotificationCenter.default.addObserver(self, selector: #selector(showSettings(_:)),
                                                   name: .deviceShaken, object: nil)
        }

        deinit { NotificationCenter.default.removeObserver(self) }

        @objc private func showSettings(_ notification: Notification) {
            guard let window = notification.object as? UIWindow,
                  window === view.window,
                  !isLaunchSettingsVisible, settingsController == nil,
                  var presenter = window.rootViewController else { return }
            // Present above the currently open sheet, preserving its navigation state.
            while let presented = presenter.presentedViewController {
                presenter = presented
            }
            guard !presenter.isBeingDismissed, !presenter.isBeingPresented else { return }
            let settings = UIHostingController(rootView: NavigationStack {
                DeveloperSettingsView { [weak self] in
                    self?.settingsController?.dismiss(animated: true) {
                        self?.settingsController = nil
                        self?.onApply()
                    }
                }
            }.appAppearance())
            settingsController = settings
            presenter.present(settings, animated: true)
            settings.presentationController?.delegate = self
        }

        func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
            settingsController = nil
            onApply()
        }
    }
}

struct DeveloperSettingsView: View {
    var buttonTitle = "Apply and close"
    var onContinue: () -> Void
    @AppStorage("developer.source") private var source = "live"
    @AppStorage("developer.scenario") private var scenario = "success"
    @AppStorage("developer.httpLogs") private var logs = ProcessInfo.processInfo.environment["HTTP_LOGGING"] == "1"
    @AppStorage("developer.authentication") private var authentication = false
    @AppStorage("developer.haptics") private var haptics = true
    @AppStorage("developer.logoPreview") private var preview = true
    @AppStorage("developer.version") private var version = ""
    @AppStorage("developer.build") private var build = ""
    @AppStorage("channelLayout") private var layout = "list"
    @State private var cacheSummary = ""

    private let diskCache = ChannelDiskCache()

    var body: some View {
        Form {
            Section {
                Text("Configure MyTV runtime, cache, and feature flags. Shake device from any screen to reopen.")
                Button(buttonTitle, action: onContinue)
                    .accessibilityIdentifier("developer-open-app")
            }
            Section("Quick presets") {
                Button {
                    source = "stub"
                    scenario = "showcase"
                    onContinue()
                } label: {
                    Label("Showcase (Populated)", systemImage: "sparkles")
                }
                .accessibilityIdentifier("developer-preset-showcase")

                Button {
                    source = "stub"
                    scenario = "empty"
                    onContinue()
                } label: {
                    Label("Empty State (Zero Results)", systemImage: "tray")
                }
                .accessibilityIdentifier("developer-preset-empty")

                Button {
                    source = "stub"
                    scenario = "offline"
                    onContinue()
                } label: {
                    Label("Offline Resilience", systemImage: "wifi.slash")
                }
                .accessibilityIdentifier("developer-preset-offline")

                Button {
                    source = "live"
                    onContinue()
                } label: {
                    Label("Live Directory", systemImage: "globe")
                }
                .accessibilityIdentifier("developer-preset-live")
            }
            Section("Cache & offline storage") {
                LabeledContent("Disk cache", value: cacheSummary.isEmpty ? "Checking..." : cacheSummary)
                Button("Purge channel cache", role: .destructive) {
                    diskCache.clear()
                    refreshCacheSummary()
                }
                .accessibilityIdentifier("developer-purge-cache")
            }
            Section("Environment") {
                Picker("Data source", selection: $source) {
                    Text("Live · IPTV directory").tag("live")
                    Text("Stub · local fixtures").tag("stub")
                }
                if source == "stub" {
                    Picker("Scenario", selection: $scenario) {
                        Text("Success").tag("success")
                        Text("Empty results").tag("empty")
                        Text("Offline error").tag("offline")
                    }
                }
                Text("Stub mode uses local channels and makes no directory or playback requests. Favorites remain on this device.")
            }
            Section("Feature flags") {
                Toggle("Authentication · AuthKit", isOn: $authentication)
                    .accessibilityIdentifier("developer-authentication")
                Text("New feature, off by default. When enabled, Open MyTV shows sign-in before the channel catalog. Apply settings to activate changes; disabling it keeps any saved session for later.")

                Toggle("Haptic feedback", isOn: $haptics)
                Toggle("Logo preview and sharing", isOn: $preview)
            }
            Section("Debug logs") {
                Toggle("HTTP logs in Xcode console", isOn: $logs)
                Text("Redacted directory requests and responses. Large responses can slow debugging. Release builds never enable these logs.")
            }
            Section("Layout") {
                Picker("Channel layout", selection: $layout) {
                    Text("List").tag("list")
                    Text("Grid").tag("grid")
                }
            }
            Section("Version simulation") {
                LabeledContent("Installed version", value: Bundle.main.appVersion)
                LabeledContent("Installed build", value: Bundle.main.buildNumber)
                TextField("Simulated version", text: $version)
                    .textInputAutocapitalization(.never).autocorrectionDisabled()
                TextField("Simulated build", text: $build)
                    .textInputAutocapitalization(.never).autocorrectionDisabled()
                Text("Changes only the version displayed in Know Your Developer.")
            }
            Section("Appearance") { AppearanceMenu() }
            Section("Privacy & Support") {
                Link(destination: URL(string: "https://github.com/Anurag-Chourasia/myTV/blob/main/Docs/PrivacyInventory.md")!) {
                    Label("Privacy Policy", systemImage: "hand.raised")
                }
                .accessibilityIdentifier("developer-privacy-policy")

                Link(destination: URL(string: "mailto:anuragchourasiaios@gmail.com")!) {
                    Label("Developer Support", systemImage: "envelope")
                }
                .accessibilityIdentifier("developer-support")

                Text("MyTV saves favorite channels locally on your device. Stream playback is direct and unauthenticated. No personal data is tracked or sold to third parties.")
                    .font(Typography.caption)
                    .foregroundStyle(DesignColor.secondary)
            }
            Section {
                Button("Reset developer settings", role: .destructive) {
                    source = "live"; scenario = "success"; logs = false
                    authentication = false; haptics = true; preview = true; version = ""; build = ""
                }
            }
        }
        .navigationTitle("Developer settings")
        .navigationBarTitleDisplayMode(.inline)
        .tint(DesignColor.primary)
        .toggleStyle(SwitchToggleStyle(tint: DesignColor.green))
        .onAppear {
            refreshCacheSummary()
        }
    }

    private func refreshCacheSummary() {
        let count = diskCache.entryCount
        if count == 0 {
            cacheSummary = "0 channels (0 KB)"
        } else {
            cacheSummary = "\(count) channels (\(diskCache.formattedFileSize))"
        }
    }
}
#endif
