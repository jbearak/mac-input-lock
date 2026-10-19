import XCTest
@testable import MacInputLock

@MainActor
final class AccessibilityTests: XCTestCase {
    func testPermissionGrantedWhileRunningRefreshesExistingModel() {
        let permission = PermissionState(granted: false)
        let model = AppModel(
            hotKey: GlobalHotKey(startAutomatically: false),
            checkAccessibility: { permission.granted }
        )
        XCTAssertFalse(model.hasAccessibilityAccess)

        permission.granted = true
        model.refreshAccessibility()

        XCTAssertTrue(model.hasAccessibilityAccess)
        XCTAssertEqual(model.state, .idle)
    }

    func testRevokedPermissionIsDetectedWithoutReopeningControls() {
        let permission = PermissionState(granted: true)
        let model = AppModel(
            hotKey: GlobalHotKey(startAutomatically: false),
            checkAccessibility: { permission.granted }
        )

        permission.granted = false
        model.refreshAccessibility()

        XCTAssertFalse(model.hasAccessibilityAccess)
    }

    func testLiveMonitorDetectsGrantWithoutAnActivationNotification() async throws {
        let permission = PermissionState(granted: false)
        let model = AppModel(
            hotKey: GlobalHotKey(startAutomatically: false),
            checkAccessibility: { permission.granted }
        )
        model.startMonitoringAccessibility()
        defer { model.stopMonitoringAccessibility() }
        permission.granted = true

        for _ in 0..<30 {
            if model.hasAccessibilityAccess { break }
            try await Task.sleep(for: .milliseconds(50))
        }

        XCTAssertTrue(model.hasAccessibilityAccess)
    }
}

@MainActor
private final class PermissionState {
    var granted: Bool
    init(granted: Bool) { self.granted = granted }
}
