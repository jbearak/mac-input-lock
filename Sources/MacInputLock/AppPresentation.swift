enum ControlWindowReason: Equatable {
    case reopened
    case hiddenStatusItem
}

enum AppPresentationAction: Equatable {
    case showPopover
    case showControlWindow(ControlWindowReason)
}

enum AppPresentationPolicy {
    static func launchAction(statusItemIsSafelyVisible: Bool) -> AppPresentationAction {
        statusItemIsSafelyVisible ? .showPopover : .showControlWindow(.hiddenStatusItem)
    }

    static var reopenAction: AppPresentationAction { .showControlWindow(.reopened) }

    static func visibilityChangeAction(
        wasVisible: Bool?,
        isVisible: Bool,
        automaticRecoveryAlreadyPresented: Bool
    ) -> AppPresentationAction? {
        guard !automaticRecoveryAlreadyPresented, wasVisible == true, !isVisible else { return nil }
        return .showControlWindow(.hiddenStatusItem)
    }
}
