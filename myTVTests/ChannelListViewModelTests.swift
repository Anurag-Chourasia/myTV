import XCTest
import Combine
import LocalizationKit
@testable import myTV

@MainActor
final class ChannelListViewModelTests: XCTestCase {

    override func setUp() async throws {
        try await super.setUp()
        UserDefaults.standard.set("stub", forKey: "developer.source")
        UserDefaults.standard.set("success", forKey: "developer.scenario")
    }

    override func tearDown() async throws {
        UserDefaults.standard.removeObject(forKey: "developer.source")
        UserDefaults.standard.removeObject(forKey: "developer.scenario")
        try await super.tearDown()
    }

    func testLoadSuccessPopulatesChannelsAndSetsLoadedState() async throws {
        let viewModel = AppDI.shared.makeChannelListViewModel()
        XCTAssertEqual(viewModel.channels.count, 0)

        await viewModel.load()

        XCTAssertFalse(viewModel.channels.isEmpty, "Channels should be populated from repository")
        if case .loaded = viewModel.state {
            // expected
        } else {
            XCTFail("Expected state to be .loaded but got \(viewModel.state)")
        }
    }

    func testLoadEmptyResultsSetsEmptyState() async throws {
        UserDefaults.standard.set("empty", forKey: "developer.scenario")
        let viewModel = AppDI.shared.makeChannelListViewModel()

        await viewModel.load()

        XCTAssertTrue(viewModel.channels.isEmpty)
        if case .empty = viewModel.state {
            // expected
        } else {
            XCTFail("Expected state to be .empty but got \(viewModel.state)")
        }
    }

    func testToggleFavoriteInsertsAndRemovesChannelID() async throws {
        let viewModel = AppDI.shared.makeChannelListViewModel()
        let testChannelID = "unit-test-ch-1"

        XCTAssertFalse(viewModel.favoriteChannelIDs.contains(testChannelID))

        viewModel.toggleFavorite(testChannelID)
        XCTAssertTrue(viewModel.favoriteChannelIDs.contains(testChannelID))

        viewModel.toggleFavorite(testChannelID)
        XCTAssertFalse(viewModel.favoriteChannelIDs.contains(testChannelID))
    }

    func testAllCountriesAndCategoriesExtractedFromLoadedChannels() async throws {
        let viewModel = AppDI.shared.makeChannelListViewModel()
        await viewModel.load()

        let countries = viewModel.allCountries
        let categories = viewModel.allCategories

        XCTAssertFalse(countries.isEmpty, "Loaded channels should yield available country codes")
        XCTAssertFalse(categories.isEmpty, "Loaded channels should yield available categories")
    }

    func testSetLayoutChangesLayoutProperty() async throws {
        let viewModel = AppDI.shared.makeChannelListViewModel()
        viewModel.setLayout(.grid)
        XCTAssertEqual(viewModel.layout, .grid)

        viewModel.setLayout(.list)
        XCTAssertEqual(viewModel.layout, .list)
    }

    func testFilterAndSortMutations() async throws {
        let viewModel = AppDI.shared.makeChannelListViewModel()
        viewModel.setGrouping(.country)
        XCTAssertEqual(viewModel.grouping, .country)

        viewModel.setScope(.favorites)
        XCTAssertEqual(viewModel.channelScope, .favorites)

        viewModel.setSectionSort(.descending)
        XCTAssertEqual(viewModel.sectionSort, .descending)

        viewModel.setChannelSort(.descending)
        XCTAssertEqual(viewModel.channelSort, .descending)

        viewModel.selectedCountries = ["FR", "US"]
        viewModel.selectedCategories = ["news"]
        viewModel.hideUnavailableStreams = true
        XCTAssertTrue(viewModel.hasSelectedCountryFilters)
        XCTAssertTrue(viewModel.hasSelectedCategoryFilters)

        viewModel.clearAllPreferences()
        XCTAssertEqual(viewModel.grouping, .name)
        XCTAssertEqual(viewModel.sectionSort, .ascending)
        XCTAssertEqual(viewModel.channelSort, .ascending)
        XCTAssertTrue(viewModel.selectedCountries.isEmpty)
        XCTAssertTrue(viewModel.selectedCategories.isEmpty)
        XCTAssertFalse(viewModel.hideUnavailableStreams)
        XCTAssertFalse(viewModel.hasSelectedCountryFilters)
        XCTAssertFalse(viewModel.hasSelectedCategoryFilters)

        viewModel.toggleFavorite("ch-1")
        XCTAssertFalse(viewModel.favoriteChannelIDs.isEmpty)
        viewModel.removeAllFavorites()
        XCTAssertTrue(viewModel.favoriteChannelIDs.isEmpty)
    }

    func testToolbarActionsAndConfirmations() async throws {
        let viewModel = AppDI.shared.makeChannelListViewModel()

        viewModel.requestAction(.clearFilters)
        XCTAssertTrue(viewModel.showAlertDialog)
        XCTAssertFalse(viewModel.toolbarAlertTitle.isEmpty)
        XCTAssertFalse(viewModel.toolbarAlertConfirm.isEmpty)
        viewModel.confirmAction()
        XCTAssertFalse(viewModel.showAlertDialog)

        viewModel.requestAction(.removeFavorites)
        XCTAssertTrue(viewModel.showAlertDialog)
        viewModel.cancelAction()
        XCTAssertFalse(viewModel.showAlertDialog)

        viewModel.requestAction(.clearCache)
        XCTAssertTrue(viewModel.showAlertDialog)
        viewModel.confirmAction()
        XCTAssertFalse(viewModel.showAlertDialog)
    }

    func testTitlesAndDisplayNames() async throws {
        let viewModel = AppDI.shared.makeChannelListViewModel()

        XCTAssertFalse(viewModel.navigationTitle.isEmpty)
        XCTAssertFalse(viewModel.cancelButtonTitle.isEmpty)
        XCTAssertFalse(viewModel.channelEmptyTitle.isEmpty)
        XCTAssertFalse(viewModel.channelEmptyMessage.isEmpty)
        XCTAssertFalse(viewModel.noResultsTitle.isEmpty)
        XCTAssertFalse(viewModel.noResultsMessage.isEmpty)
        XCTAssertFalse(viewModel.sortAndFilterSectionTitle.isEmpty)
        XCTAssertFalse(viewModel.groupByMenuTitle.isEmpty)
        XCTAssertFalse(viewModel.sectionSortingTitle.isEmpty)
        XCTAssertFalse(viewModel.channelSortingTitle.isEmpty)
        XCTAssertFalse(viewModel.sortingMenuTitle.isEmpty)
        XCTAssertFalse(viewModel.countriesFilterTitle.isEmpty)
        XCTAssertFalse(viewModel.categoriesFilterTitle.isEmpty)
        XCTAssertFalse(viewModel.filterMenuTitle.isEmpty)
        XCTAssertFalse(viewModel.actionsSectionTitle.isEmpty)
        XCTAssertFalse(viewModel.clearCacheActionTitle.isEmpty)
        XCTAssertFalse(viewModel.clearFiltersActionTitle.isEmpty)
        XCTAssertFalse(viewModel.removeFavoritesActionTitle.isEmpty)
        XCTAssertFalse(viewModel.layoutSectionTitle.isEmpty)
        XCTAssertFalse(viewModel.appearanceSectionTitle.isEmpty)
        XCTAssertFalse(viewModel.aboutSectionTitle.isEmpty)
        XCTAssertFalse(viewModel.layoutMenuTitle.isEmpty)
        XCTAssertFalse(viewModel.errorViewModel.title.isEmpty)
        XCTAssertFalse(viewModel.offlineBannerViewModel.message.isEmpty)

        XCTAssertEqual(viewModel.title(for: .list), String(\MyTVStrings.layoutList))
        XCTAssertEqual(viewModel.title(for: .grid), String(\MyTVStrings.layoutGrid))

        XCTAssertFalse(viewModel.countryDisplayName("FR").isEmpty)
        XCTAssertFalse(viewModel.categoryDisplayName("news").isEmpty)
        XCTAssertFalse(viewModel.countrySortKey("FR").isEmpty)
        XCTAssertFalse(viewModel.categorySortKey("news").isEmpty)

        viewModel.setGrouping(.country)
        XCTAssertFalse(viewModel.sectionTitle(for: "FR").isEmpty)
        viewModel.setGrouping(.category)
        XCTAssertFalse(viewModel.sectionTitle(for: "news").isEmpty)
        viewModel.setGrouping(.name)
        XCTAssertEqual(viewModel.sectionTitle(for: "Alpha"), "Alpha")

        viewModel.selectionHaptic()
    }

    func testAccessibilityAndGridState() async throws {
        let viewModel = AppDI.shared.makeChannelListViewModel()

        viewModel.setLayout(.grid)
        XCTAssertTrue(viewModel.shouldShowGrid(isAccessibilitySize: false))
        XCTAssertFalse(viewModel.shouldShowGrid(isAccessibilitySize: true))

        viewModel.refreshAccessibilityLayoutState(isAccessibilitySize: true)
        XCTAssertEqual(viewModel.layout, .list)
        XCTAssertEqual(viewModel.gridAlert?.id, "autoList")
        XCTAssertFalse(viewModel.gridAlertTitle.isEmpty)
        XCTAssertFalse(viewModel.gridAlertMessage.isEmpty)
        XCTAssertFalse(viewModel.gridAlertOk.isEmpty)

        viewModel.clearGridAlert()
        XCTAssertNil(viewModel.gridAlert)

        viewModel.handleGridUnavailable()
        XCTAssertEqual(viewModel.gridAlert?.id, "gridUnavailable")
        XCTAssertFalse(viewModel.gridAlertTitle.isEmpty)
        XCTAssertFalse(viewModel.gridAlertMessage.isEmpty)
        XCTAssertFalse(viewModel.gridAlertOk.isEmpty)
    }
}
