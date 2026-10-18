import AppKit
import Observation

@MainActor
@Observable
final class AppPreferences {
    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let applyDockVisibility: @MainActor (Bool) -> Void

    var showInDock: Bool {
        didSet {
            guard showInDock != oldValue else { return }
            defaults.set(showInDock, forKey: "showInDock")
            applyDockVisibility(showInDock)
        }
    }

    init(
        defaults: UserDefaults = .standard,
        applyDockVisibility: @escaping @MainActor (Bool) -> Void = {
            NSApplication.shared.setActivationPolicy($0 ? .regular : .accessory)
        }
    ) {
        self.defaults = defaults
        self.applyDockVisibility = applyDockVisibility
        showInDock = defaults.bool(forKey: "showInDock")
        applyDockVisibility(showInDock)
    }
}
