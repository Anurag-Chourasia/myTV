import XCTest
@testable import myTV

@MainActor
final class MultiSelectViewModelTests: XCTestCase {

    func testInitialSelectionAndDraftState() {
        let options = ["News", "Sports", "Music", "Cinema"]
        let initial: Set<String> = ["News"]

        let viewModel = MultiSelectViewModel(
            title: "Categories",
            options: options,
            initialSelection: initial,
            allowsMultipleSelection: true,
            labelForOption: { $0 },
            sortKeyForOption: { $0 },
            haptics: AppDI.shared.getHaptics()
        )

        XCTAssertEqual(viewModel.draftSelection, initial)
        XCTAssertFalse(viewModel.canApply, "canApply should be false when draft matches initial")
        XCTAssertTrue(viewModel.isSelected("News"))
        XCTAssertFalse(viewModel.isSelected("Sports"))
    }

    func testToggleUpdatesDraftSelectionAndCanApply() {
        let options = ["News", "Sports"]
        let viewModel = MultiSelectViewModel(
            title: "Categories",
            options: options,
            initialSelection: ["News"],
            allowsMultipleSelection: true,
            labelForOption: { $0 },
            sortKeyForOption: { $0 },
            haptics: AppDI.shared.getHaptics()
        )

        viewModel.toggle("Sports")
        XCTAssertTrue(viewModel.draftSelection.contains("Sports"))
        XCTAssertTrue(viewModel.canApply, "canApply should be true after toggling an unselected item")

        viewModel.toggle("Sports")
        XCTAssertFalse(viewModel.draftSelection.contains("Sports"))
        XCTAssertFalse(viewModel.canApply, "canApply should be false when back to initial")
    }

    func testApplyCommitsDraftSelection() {
        let options = ["News", "Sports", "Music"]
        let viewModel = MultiSelectViewModel(
            title: "Categories",
            options: options,
            initialSelection: ["News"],
            allowsMultipleSelection: true,
            labelForOption: { $0 },
            sortKeyForOption: { $0 },
            haptics: AppDI.shared.getHaptics()
        )

        viewModel.toggle("Sports")
        let committed = viewModel.apply()

        XCTAssertEqual(committed, ["News", "Sports"])
        XCTAssertFalse(viewModel.canApply, "canApply should reset to false after apply")
    }

    func testClearEmptiesDraftSelection() {
        let options = ["News", "Sports"]
        let viewModel = MultiSelectViewModel(
            title: "Categories",
            options: options,
            initialSelection: ["News", "Sports"],
            allowsMultipleSelection: true,
            labelForOption: { $0 },
            sortKeyForOption: { $0 },
            haptics: AppDI.shared.getHaptics()
        )

        viewModel.clear()
        XCTAssertTrue(viewModel.draftSelection.isEmpty)
        XCTAssertTrue(viewModel.canApply)
    }

    func testSingleSelectionModeReplacesPrevious() {
        let options = ["Light", "Dark", "System"]
        let viewModel = MultiSelectViewModel(
            title: "Theme",
            options: options,
            initialSelection: ["Light"],
            allowsMultipleSelection: false,
            labelForOption: { $0 },
            sortKeyForOption: { $0 },
            haptics: AppDI.shared.getHaptics()
        )

        viewModel.toggle("Dark")
        XCTAssertEqual(viewModel.draftSelection, ["Dark"])
    }
}
