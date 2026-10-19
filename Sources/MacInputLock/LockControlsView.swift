import SwiftUI

struct LockControlsView: View {
    static let size = NSSize(width: 360, height: 470)
    @Bindable var model: AppModel
    @Bindable var preferences: AppPreferences
    let dismiss: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @FocusState private var editingSequence: Bool
    private var hasAccess: Bool { model.hasAccessibilityAccess }

    var body: some View {
        VStack(spacing: 0) {
            header
            Spacer(minLength: 8)
            if isActive {
                activeControls
            } else {
                configuration
            }
            Spacer(minLength: 8)
            shortcut
            footer
        }
        .padding(24)
        .padding(.top, 12)
        .frame(width: Self.size.width, height: Self.size.height)
        .background(Color(nsColor: .windowBackgroundColor))
        .tint(.indigo)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: isActive)
        .onAppear { model.refreshAccessibility() }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            model.refreshAccessibility()
        }
        .onChange(of: model.sequenceText) { _, _ in model.saveSequence() }
        .task(id: isLocked) {
            guard isLocked else { return }
            try? await Task.sleep(for: .seconds(2))
            guard !Task.isCancelled, isLocked else { return }
            dismiss()
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Image(systemName: isLocked ? "lock.fill" : "lock.open.fill")
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(.white)
                .frame(width: 48, height: 48)
                .background(.indigo.gradient, in: RoundedRectangle(cornerRadius: 14))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text("Input Lock").font(.title3.weight(.semibold))
                Text(isLocked ? "The show goes on." : "Keep the video playing.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
    }

    private var configuration: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Type this to unlock")
                    .font(.callout.weight(.medium))
                TextField("sesame", text: $model.sequenceText)
                    .font(.system(size: 24, weight: .medium, design: .monospaced))
                    .textFieldStyle(.plain)
                    .focused($editingSequence)
                    .accessibilityLabel("Unlock sequence")
                    .onSubmit { editingSequence = false }
                Text("Case-sensitive. You can change it anytime.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.quaternary.opacity(0.45), in: RoundedRectangle(cornerRadius: 14))

            if !hasAccess {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "hand.raised").foregroundStyle(.indigo)
                    VStack(alignment: .leading, spacing: 5) {
                        Text("One-time setup").font(.callout.weight(.medium))
                        Text("Allow Accessibility access to block input.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        HStack(spacing: 12) {
                            Button("Open Settings…", action: openAccessibilitySettings)
                            Button("Already enabled?", action: showPermissionHelp)
                        }
                        .buttonStyle(.link)
                        .font(.callout)
                    }
                }
            }

            if let message = model.validationMessage {
                Text(message).font(.caption).foregroundStyle(.red)
            } else if case let .error(message) = model.state, hasAccess {
                Text(message).font(.caption).foregroundStyle(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Button {
                editingSequence = false
                model.refreshAccessibility()
                if model.hasAccessibilityAccess {
                    model.start()
                } else {
                    openAccessibilitySettings()
                }
            } label: {
                Label(hasAccess ? "Lock input" : "Enable input locking…", systemImage: hasAccess ? "lock.fill" : "hand.raised")
                    .font(.body.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(model.validationMessage != nil)
            .help("Blocks keyboard, mouse, and trackpad after five seconds")
            Text("Blocks keyboard, mouse and trackpad.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
        }
    }

    @ViewBuilder
    private var activeControls: some View {
        VStack(spacing: 16) {
            if case let .arming(seconds) = model.state {
                Text("\(seconds)")
                    .font(.system(size: 72, weight: .light, design: .rounded))
                    .monospacedDigit()
                    .contentTransition(.numericText(countsDown: true))
                    .foregroundStyle(.indigo)
                    .accessibilityLabel("Locking in \(seconds) seconds")
                Text("Hands off in a moment.").font(.headline)
                unlockReminder
                Button("Cancel") { model.cancelArming() }
                    .keyboardShortcut(.cancelAction)
                    .controlSize(.large)
            } else {
                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: 56, weight: .light))
                    .foregroundStyle(.indigo)
                    .accessibilityHidden(true)
                Text("Input is locked").font(.title2.weight(.semibold))
                unlockReminder
                Text("Video and sound keep playing.")
                    .font(.callout).foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var unlockReminder: some View {
        (Text("Type ") + Text(model.sequenceText).font(.system(.body, design: .monospaced).weight(.semibold)) + Text(" to unlock."))
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var shortcut: some View {
        HStack(spacing: 12) {
            HStack(spacing: 5) {
                ForEach(["⌃", "⌥", "⌘", "D"], id: \.self) { key in
                    Text(key)
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .frame(width: 25, height: 24)
                        .background(.background, in: RoundedRectangle(cornerRadius: 5))
                        .overlay(RoundedRectangle(cornerRadius: 5).strokeBorder(.quaternary))
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Control Option Command D")
            Text("Lock or unlock instantly")
                .font(.caption).foregroundStyle(.secondary)
        }
        .padding(.bottom, 16)
    }

    private var footer: some View {
        VStack(spacing: 14) {
            Divider()
            HStack {
                Toggle("Show in Dock", isOn: $preferences.showInDock)
                    .toggleStyle(.switch)
                    .controlSize(.mini)
                    .font(.caption)
                Spacer()
                Button("Quit") {
                    model.stop()
                    NSApp.terminate(nil)
                }
                .buttonStyle(.plain)
                .font(.caption)
                .foregroundStyle(.secondary)
                .keyboardShortcut("q")
            }
            .disabled(isActive)
        }
    }

    private var isLocked: Bool { model.state == .locked }
    private var isActive: Bool {
        switch model.state {
        case .arming, .locked: true
        default: false
        }
    }

    private func showPermissionHelp() {
        model.refreshAccessibility()
        guard !model.hasAccessibilityAccess else { return }
        let alert = NSAlert()
        alert.messageText = "Refresh Accessibility access"
        alert.informativeText = "macOS may still trust a previous build. In Accessibility settings, select Mac Input Lock, click − to remove it, then click + and choose /Applications/Mac Input Lock.app. The app checks for access automatically."
        alert.addButton(withTitle: "Open Settings")
        alert.addButton(withTitle: "Cancel")
        if alert.runModal() == .alertFirstButtonReturn { openAccessibilitySettings() }
    }

    private func openAccessibilitySettings() {
        AccessibilityPermission.request()
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") else { return }
        NSWorkspace.shared.open(url)
    }
}
