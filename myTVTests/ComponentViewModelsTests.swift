import XCTest
import LocalizationKit
@testable import myTV

@MainActor
final class ComponentViewModelsTests: XCTestCase {

    func testAppearanceMenuViewModel() {
        let vm = AppearanceMenuViewModel()
        XCTAssertFalse(vm.menuTitle.isEmpty)
        XCTAssertEqual(vm.title(for: .system), String(\MyTVStrings.appearanceSystem))
        XCTAssertEqual(vm.title(for: .light), String(\MyTVStrings.appearanceLight))
        XCTAssertEqual(vm.title(for: .dark), String(\MyTVStrings.appearanceDark))
    }

    func testErrorViewModel() {
        let vm = ErrorViewModel.generic
        XCTAssertFalse(vm.title.isEmpty)
        XCTAssertFalse(vm.retryTitle.isEmpty)
    }

    func testLoadingViewModel() {
        let vm = LoadingViewModel.streamPreparationDefault
        XCTAssertFalse(vm.message.isEmpty)
    }

    func testOfflineBannerViewModel() {
        let vm = OfflineBannerViewModel.default
        XCTAssertFalse(vm.message.isEmpty)
    }
}
