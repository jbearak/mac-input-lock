import SwiftUI

@MainActor
final class StatusBarController: NSObject {
    private let model = AppModel()
    private let preferences = AppPreferences()
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private let popover = NSPopover()
    private var window: NSWindow?
    private var lastVisibility: Bool?
    private var recoveryPresented = false
    private var lastState: AppModel.State?
    private var visibilityTask: Task<Void, Never>?

    override init() {
        super.init()
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: makeControls())
        if let button = statusItem.button {
            button.target = self
            button.action = #selector(togglePopover)
        }
        for name in [NSApplication.didChangeScreenParametersNotification, NSWindow.didChangeScreenNotification] {
            NotificationCenter.default.addObserver(self, selector: #selector(displayChanged), name: name, object: nil)
        }
        for name in [NSWorkspace.didWakeNotification, NSWorkspace.activeSpaceDidChangeNotification] {
            NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(displayChanged), name: name, object: nil)
        }
        observeState()
    }

    func stop() { model.stop() }

    func showOnLaunch() {
        let visible = statusItemIsVisible
        lastVisibility = visible
        perform(AppPresentationPolicy.launchAction(statusItemIsSafelyVisible: visible))
    }

    func showWindow() {
        popover.performClose(nil)
        if window == nil {
            let window = NSWindow(
                contentRect: NSRect(origin: .zero, size: LockControlsView.size),
                styleMask: [.titled, .closable, .fullSizeContentView],
                backing: .buffered,
                defer: false
            )
            window.title = "Mac Input Lock"
            window.titleVisibility = .hidden
            window.titlebarAppearsTransparent = true
            window.isReleasedWhenClosed = false
            window.contentViewController = NSHostingController(rootView: makeControls())
            window.center()
            self.window = window
        }
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
    }

    private func makeControls() -> LockControlsView {
        LockControlsView(model: model, preferences: preferences) { [weak self] in
            self?.popover.performClose(nil)
            self?.window?.close()
        }
    }

    @objc private func togglePopover() {
        if popover.isShown {
            popover.performClose(nil)
        } else if let button = statusItem.button {
            window?.close()
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }

    private var statusItemIsVisible: Bool {
        guard let button = statusItem.button, let window = button.window else { return false }
        let frame = window.convertToScreen(button.convert(button.bounds, to: nil))
        guard let screen = NSScreen.screens.first(where: { $0.frame.intersects(frame) }) else { return false }
        return StatusItemVisibility.isVisible(frame: frame, on: screen)
    }

    private func perform(_ action: AppPresentationAction) {
        switch action {
        case .showPopover: togglePopover()
        case let .showControlWindow(reason):
            recoveryPresented = reason == .hiddenStatusItem || recoveryPresented
            showWindow()
        }
    }

    @objc private func displayChanged(_ notification: Notification) {
        visibilityTask?.cancel()
        visibilityTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(200))
            guard !Task.isCancelled, let self else { return }
            let visible = statusItemIsVisible
            let action = AppPresentationPolicy.visibilityChangeAction(
                wasVisible: lastVisibility,
                isVisible: visible,
                automaticRecoveryAlreadyPresented: recoveryPresented
            )
            lastVisibility = visible
            if let action { perform(action) }
        }
    }

    private func observeState() {
        withObservationTracking {
            let state = model.state
            updateStatusItem(state)
            if let lastState, let feedback = InputFeedbackPolicy.feedback(from: lastState, to: state) {
                InputFeedbackHUDController.shared.show(feedback)
            }
            lastState = state
        } onChange: { [weak self] in
            Task { @MainActor in self?.observeState() }
        }
    }

    private func updateStatusItem(_ state: AppModel.State) {
        let symbol: String
        let label: String
        switch state {
        case .idle, .error: (symbol, label) = ("lock.open", "Mac Input Lock")
        case .arming: (symbol, label) = ("timer", "Locking soon")
        case .locked: (symbol, label) = ("lock.fill", "Input locked")
        case .restored: (symbol, label) = ("checkmark", "Input restored")
        }
        statusItem.button?.image = NSImage(systemSymbolName: symbol, accessibilityDescription: label)
        statusItem.button?.toolTip = label
    }
}
