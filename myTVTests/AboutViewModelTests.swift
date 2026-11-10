import XCTest
import Combine
import LocalizationKit
@testable import myTV

@MainActor
final class AboutViewModelTests: XCTestCase {

    private final class MockReachabilityService: ReachabilityService, @unchecked Sendable {
        private let subject = CurrentValueSubject<Bool, Never>(true)
        var isOnlinePublisher: AnyPublisher<Bool, Never> {
            subject.eraseToAnyPublisher()
        }
        var isOnline: Bool { subject.value }
        func setOnline(_ online: Bool) { subject.send(online) }
    }

    func testInitialStateAndStaticTitles() {
        let reachability = MockReachabilityService()
        let haptics = AppDI.shared.getHaptics()
        let vm = AboutViewModel(reachability: reachability, haptics: haptics)

        XCTAssertFalse(vm.navigationTitle.isEmpty)
        XCTAssertFalse(vm.appName.isEmpty)
        XCTAssertFalse(vm.appVersionPrefix.isEmpty)
        XCTAssertFalse(vm.disclaimerTitle.isEmpty)
        XCTAssertFalse(vm.disclaimerText.isEmpty)
        XCTAssertFalse(vm.socialTitle.isEmpty)
        XCTAssertFalse(vm.layoutMenuTitle.isEmpty)
        XCTAssertFalse(vm.layoutMenuSectionTitle.isEmpty)
        XCTAssertFalse(vm.appearanceMenuSectionTitle.isEmpty)
        XCTAssertFalse(vm.appInfoTitle.isEmpty)
        XCTAssertFalse(vm.invalidLinkAlertTitle.isEmpty)
        XCTAssertFalse(vm.invalidLinkAlertOk.isEmpty)
        XCTAssertFalse(vm.invalidLinkAlertMessage.isEmpty)
        XCTAssertFalse(vm.offlineBannerViewModel.message.isEmpty)

        XCTAssertEqual(vm.title(for: .list), String(\MyTVStrings.layoutList))
        XCTAssertEqual(vm.title(for: .grid), String(\MyTVStrings.layoutGrid))
    }

    func testEnforceListIfAccessibility() {
        let reachability = MockReachabilityService()
        let haptics = AppDI.shared.getHaptics()
        let vm = AboutViewModel(reachability: reachability, haptics: haptics)

        vm.setLayout(.grid)
        XCTAssertEqual(vm.layout, .grid)

        vm.enforceListIfAccessibility(true)
        XCTAssertEqual(vm.layout, .list)
        XCTAssertEqual(vm.gridAlert?.id, "autoList")
        XCTAssertFalse(vm.gridAlertTitle.isEmpty)
        XCTAssertFalse(vm.gridAlertMessage.isEmpty)
        XCTAssertFalse(vm.gridAlertOk.isEmpty)

        vm.clearGridAlert()
        XCTAssertNil(vm.gridAlert)
        XCTAssertEqual(vm.gridAlertTitle, "")
        XCTAssertEqual(vm.gridAlertMessage, "")
    }

    func testHandleGridUnavailable() {
        let reachability = MockReachabilityService()
        let haptics = AppDI.shared.getHaptics()
        let vm = AboutViewModel(reachability: reachability, haptics: haptics)

        vm.handleGridUnavailable()
        XCTAssertEqual(vm.gridAlert?.id, "gridUnavailable")
        XCTAssertFalse(vm.gridAlertTitle.isEmpty)
        XCTAssertFalse(vm.gridAlertMessage.isEmpty)
        XCTAssertFalse(vm.gridAlertOk.isEmpty)

        vm.clearGridAlert()
        XCTAssertNil(vm.gridAlert)
    }

    func testLayoutStorageAndAccessibilityChecks() {
        let reachability = MockReachabilityService()
        let haptics = AppDI.shared.getHaptics()
        let vm = AboutViewModel(reachability: reachability, haptics: haptics)

        vm.setLayout(.list)
        XCTAssertFalse(vm.shouldUseGridLayout(isAccessibilitySize: false))
        XCTAssertFalse(vm.shouldUseGridLayout(isAccessibilitySize: true))

        vm.setLayout(.grid)
        XCTAssertTrue(vm.shouldUseGridLayout(isAccessibilitySize: false))
        XCTAssertFalse(vm.shouldUseGridLayout(isAccessibilitySize: true))

        vm.syncLayoutFromStorage()
        vm.refreshAccessibilityLayoutState(isAccessibilitySize: false)
        XCTAssertEqual(vm.layout, .grid)

        vm.refreshAccessibilityLayoutState(isAccessibilitySize: true)
        XCTAssertEqual(vm.layout, .list)

        vm.selectionHaptic()
    }

    func testReachabilityObservation() async {
        let reachability = MockReachabilityService()
        let haptics = AppDI.shared.getHaptics()
        let vm = AboutViewModel(reachability: reachability, haptics: haptics)

        reachability.setOnline(false)
        try? await Task.sleep(nanoseconds: 50_000_000)
        XCTAssertTrue(vm.showOfflineBanner)

        reachability.setOnline(true)
        try? await Task.sleep(nanoseconds: 50_000_000)
        XCTAssertFalse(vm.showOfflineBanner)
    }
}
