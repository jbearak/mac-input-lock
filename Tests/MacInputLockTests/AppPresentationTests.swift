import XCTest
@testable import MacInputLock

@MainActor
final class AppPresentationTests: XCTestCase {
    func testLaunchPointsToStatusItemWhenItIsSafelyVisible() {
        XCTAssertEqual(
            AppPresentationPolicy.launchAction(statusItemIsSafelyVisible: true),
            .showPopover
        )
    }

    func testLaunchShowsHiddenItemWindowWhenStatusItemIsNotSafelyVisible() {
        XCTAssertEqual(
            AppPresentationPolicy.launchAction(statusItemIsSafelyVisible: false),
            .showControlWindow(.hiddenStatusItem)
        )
    }

    func testReopeningAlwaysShowsNormalControlWindow() {
        XCTAssertEqual(
            AppPresentationPolicy.reopenAction,
            .showControlWindow(.reopened)
        )
    }

    func testVisibleItemBecomingHiddenShowsRecoveryWindow() {
        XCTAssertEqual(
            AppPresentationPolicy.visibilityChangeAction(
                wasVisible: true,
                isVisible: false,
                automaticRecoveryAlreadyPresented: false
            ),
            .showControlWindow(.hiddenStatusItem)
        )
    }

    func testAutomaticRecoveryWindowIsOnlyShownOncePerLaunch() {
        XCTAssertNil(
            AppPresentationPolicy.visibilityChangeAction(
                wasVisible: true,
                isVisible: false,
                automaticRecoveryAlreadyPresented: true
            )
        )
    }

    func testVisibleOrNewlyVisibleItemsDoNotShowRecoveryWindow() {
        XCTAssertNil(AppPresentationPolicy.visibilityChangeAction(
            wasVisible: nil,
            isVisible: true,
            automaticRecoveryAlreadyPresented: false
        ))
        XCTAssertNil(AppPresentationPolicy.visibilityChangeAction(
            wasVisible: false,
            isVisible: true,
            automaticRecoveryAlreadyPresented: false
        ))
        XCTAssertNil(AppPresentationPolicy.visibilityChangeAction(
            wasVisible: true,
            isVisible: true,
            automaticRecoveryAlreadyPresented: false
        ))
    }

    func testDockPreferenceDefaultsToMenuBarOnlyAndAppliesIt() {
        let defaults = makeDefaults()
        var appliedValues: [Bool] = []

        let preferences = AppPreferences(defaults: defaults) { appliedValues.append($0) }

        XCTAssertFalse(preferences.showInDock)
        XCTAssertEqual(appliedValues, [false])
    }

    func testDockPreferencePersistsAndAppliesChanges() {
        let defaults = makeDefaults()
        var appliedValues: [Bool] = []
        let preferences = AppPreferences(defaults: defaults) { appliedValues.append($0) }

        preferences.showInDock = true

        XCTAssertEqual(appliedValues, [false, true])

        var restoredValues: [Bool] = []
        let restored = AppPreferences(defaults: defaults) { restoredValues.append($0) }
        XCTAssertTrue(restored.showInDock)
        XCTAssertEqual(restoredValues, [true])
    }

    func testSuccessfulCountdownLockShowsLockedFeedback() {
        XCTAssertEqual(
            InputFeedbackPolicy.feedback(from: .arming(secondsRemaining: 1), to: .locked),
            .locked
        )
    }

    func testSuccessfulHotKeyLockShowsLockedFeedback() {
        XCTAssertEqual(
            InputFeedbackPolicy.feedback(from: .idle, to: .locked),
            .locked
        )
    }

    func testUnlockShowsRestoredFeedback() {
        XCTAssertEqual(
            InputFeedbackPolicy.feedback(from: .locked, to: .restored),
            .restored
        )
    }

    func testUnsuccessfulOrIntermediateStatesDoNotShowFeedback() {
        XCTAssertNil(InputFeedbackPolicy.feedback(from: .idle, to: .arming(secondsRemaining: 5)))
        XCTAssertNil(InputFeedbackPolicy.feedback(from: .arming(secondsRemaining: 1), to: .error("Failed")))
        XCTAssertNil(InputFeedbackPolicy.feedback(from: .restored, to: .idle))
    }

    func testLockedFeedbackUsesRedClosedLockPresentation() {
        XCTAssertEqual(InputFeedback.locked.title, "Input locked")
        XCTAssertEqual(InputFeedback.locked.tint, .red)
        XCTAssertEqual(InputFeedback.locked.initialSymbol, "lock.open.fill")
        XCTAssertEqual(InputFeedback.locked.finalSymbol, "lock.fill")
    }

    func testRestoredFeedbackUsesGreenOpenLockPresentation() {
        XCTAssertEqual(InputFeedback.restored.title, "Input restored")
        XCTAssertEqual(InputFeedback.restored.tint, .green)
        XCTAssertEqual(InputFeedback.restored.initialSymbol, "lock.fill")
        XCTAssertEqual(InputFeedback.restored.finalSymbol, "lock.open.fill")
    }

    private func makeDefaults() -> UserDefaults {
        let suiteName = "AppPresentationTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }
}
