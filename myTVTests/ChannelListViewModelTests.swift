import XCTest
import Combine
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
}
