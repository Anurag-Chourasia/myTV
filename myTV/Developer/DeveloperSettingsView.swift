import SwiftUI
import DesignTokensKit

struct TVLaunchView: View {
    #if DEBUG
    @State private var showingLaunchSettings = true
    @State private var configurationID = UUID()
    #endif

    var body: some View {
        #if DEBUG
        Group {
            if showingLaunchSettings {
                NavigationStack {
                    DeveloperSettingsView(buttonTitle: "Open MyTV") {
                        showingLaunchSettings = false
                    }
                }
            } else {
                ChannelListView(viewModel: AppDI.shared.makeChannelListViewModel()).id(configurationID)
            }
        }
        .background(DebugSettingsPresenter(isLaunchSettingsVisible: showingLaunchSettings) {
            configurationID = UUID()
        })
        #else
        ChannelListView(viewModel: AppDI.shared.makeChannelListViewModel())
        #endif
    }
}

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
    @AppStorage("developer.haptics") private var haptics = true
    @AppStorage("developer.logoPreview") private var preview = true
    @AppStorage("developer.version") private var version = ""
    @AppStorage("developer.build") private var build = ""
    @AppStorage("channelLayout") private var layout = "list"

    var body: some View {
        Form {
            Section {
                Text("Configure MyTV, then continue. Shake the device from any screen to return to these settings.")
                Button(buttonTitle, action: onContinue)
                    .accessibilityIdentifier("developer-open-app")
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
            Section {
                Button("Reset developer settings", role: .destructive) {
                    source = "live"; scenario = "success"; logs = false
                    haptics = true; preview = true; version = ""; build = ""
                }
            }
        }
        .navigationTitle("Developer settings")
        .navigationBarTitleDisplayMode(.inline)
        .tint(DesignColor.primary)
        .toggleStyle(SwitchToggleStyle(tint: DesignColor.green))
    }
}
#endif
