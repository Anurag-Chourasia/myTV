import XCTest
import SwiftUI
import SnapshotTestingKit
@testable import myTV

@MainActor
final class ComponentSnapshotTests: XCTestCase {

    // MARK: - Empty State

    func testEmptyStateView() throws {
        guard SnapshotDevice.current == .iPhone11 else {
            throw XCTSkip("Skipping base iPhone 11 component test on \(SnapshotDevice.current?.rawValue ?? "unknown device")")
        }

        let view = EmptyStateView(
            title: "No Channels",
            message: "Try searching for a different channel or category.",
            systemImage: "tv.slash"
        )

        SnapshotAssert.assertVariants(
            of: view,
            on: .iPhone11,
            named: "empty-state"
        )
    }

    // MARK: - Error State

    func testErrorView() throws {
        guard SnapshotDevice.current == .iPhone11 else {
            throw XCTSkip("Skipping base iPhone 11 component test on \(SnapshotDevice.current?.rawValue ?? "unknown device")")
        }

        let view = ErrorView(
            viewModel: ErrorViewModel(title: "Playback Error", retryTitle: "Reload Channel"),
            message: "The stream could not be loaded. Please check your network.",
            retry: {}
        )

        SnapshotAssert.assertVariants(
            of: view,
            on: .iPhone11,
            named: "error-state"
        )
    }

    // MARK: - Loading State

    func testLoadingView() throws {
        guard SnapshotDevice.current == .iPhone11 else {
            throw XCTSkip("Skipping base iPhone 11 component test on \(SnapshotDevice.current?.rawValue ?? "unknown device")")
        }

        let view = LoadingView(
            viewModel: LoadingViewModel(message: "Connecting to stream...")
        )

        SnapshotAssert.assertVariants(
            of: view,
            on: .iPhone11,
            named: "loading-state"
        )
    }

    // MARK: - Offline Banner

    func testOfflineBanner() throws {
        guard SnapshotDevice.current == .iPhone11 else {
            throw XCTSkip("Skipping base iPhone 11 component test on \(SnapshotDevice.current?.rawValue ?? "unknown device")")
        }

        let view = OfflineBanner(
            viewModel: OfflineBannerViewModel(message: "Offline - displaying cached channels")
        )

        SnapshotAssert.assertVariants(
            of: view,
            on: .iPhone11,
            named: "offline-banner"
        )
    }

    // MARK: - About Screen

    func testAboutView() throws {
        guard SnapshotDevice.current == .iPhone11 else {
            throw XCTSkip("Skipping base iPhone 11 component test on \(SnapshotDevice.current?.rawValue ?? "unknown device")")
        }

        let viewModel = AppDI.shared.makeAboutViewModel()
        let view = NavigationStack {
            AboutView(viewModel: viewModel)
        }

        SnapshotAssert.assertVariants(
            of: view,
            on: .iPhone11,
            named: "about-screen"
        )
    }

    // MARK: - Channel Row View

    func testChannelRowView() throws {
        guard SnapshotDevice.current == .iPhone11 else {
            throw XCTSkip("Skipping base iPhone 11 component test on \(SnapshotDevice.current?.rawValue ?? "unknown device")")
        }

        let channel = Channel(
            id: "test-news",
            name: "World News 24/7",
            country: "US",
            categories: ["News", "World"],
            isNSFW: false,
            logoURL: nil,
            hasStreams: true
        )

        let view = ChannelRowView(
            channel: channel,
            isFavorite: true,
            onFavoriteToggle: {}
        )
        .padding()

        SnapshotAssert.assertVariants(
            of: view,
            on: .iPhone11,
            named: "channel-row"
        )
    }

    // MARK: - Channel Grid View

    func testChannelGridView() throws {
        guard SnapshotDevice.current == .iPhone11 else {
            throw XCTSkip("Skipping base iPhone 11 component test on \(SnapshotDevice.current?.rawValue ?? "unknown device")")
        }

        let channel = Channel(
            id: "test-science",
            name: "Discovery Science",
            country: "GB",
            categories: ["Science"],
            isNSFW: false,
            logoURL: nil,
            hasStreams: true
        )

        let view = ChannelGridView(
            channel: channel,
            isFavorite: false,
            onFavoriteToggle: {}
        )
        .frame(width: 170, height: 180)
        .padding()

        SnapshotAssert.assertVariants(
            of: view,
            on: .iPhone11,
            named: "channel-grid"
        )
    }

    // MARK: - Skeleton Loading View

    func testSkeletonListView() throws {
        guard SnapshotDevice.current == .iPhone11 else {
            throw XCTSkip("Skipping base iPhone 11 component test on \(SnapshotDevice.current?.rawValue ?? "unknown device")")
        }

        let view = SkeletonListView()

        SnapshotAssert.assertVariants(
            of: view,
            on: .iPhone11,
            named: "skeleton-loading"
        )
    }

    // MARK: - Stream List Screen

    func testStreamListView() async throws {
        guard SnapshotDevice.current == .iPhone11 else {
            throw XCTSkip("Skipping base iPhone 11 component test on \(SnapshotDevice.current?.rawValue ?? "unknown device")")
        }

        let viewModel = AppDI.shared.makeStreamListViewModel()
        let view = NavigationStack {
            StreamListView(viewModel: viewModel, channelId: "debug-news", channelName: "Demo News")
        }

        SnapshotAssert.assertVariants(
            of: view,
            on: .iPhone11,
            named: "stream-list"
        )
    }

    // MARK: - Channel Sticky Bar (Scope Switcher)

    func testChannelStickyBar() throws {
        guard SnapshotDevice.current == .iPhone11 else {
            throw XCTSkip("Skipping base iPhone 11 component test on \(SnapshotDevice.current?.rawValue ?? "unknown device")")
        }

        struct StickyBarContainer: View {
            @State var scope: ChannelListViewModel.ChannelScope = .all
            var body: some View {
                ChannelStickyBar(scope: $scope)
                    .padding()
            }
        }

        SnapshotAssert.assertVariants(
            of: StickyBarContainer(),
            on: .iPhone11,
            named: "channel-sticky-bar"
        )
    }

    // MARK: - Layout Switch Menu

    func testLayoutSwitchMenu() throws {
        guard SnapshotDevice.current == .iPhone11 else {
            throw XCTSkip("Skipping base iPhone 11 component test on \(SnapshotDevice.current?.rawValue ?? "unknown device")")
        }

        let view = LayoutSwitchMenu(
            selectedLayout: .list,
            onSelectLayout: { _ in },
            isAccessibilitySize: false,
            menuTitle: "Layout",
            titleForLayout: { $0 == .list ? "List" : "Grid" }
        )
        .padding()

        SnapshotAssert.assertVariants(
            of: view,
            on: .iPhone11,
            named: "layout-switch-menu"
        )
    }

    // MARK: - Multi-Select View (Filter Modal)

    func testMultiSelectView() throws {
        guard SnapshotDevice.current == .iPhone11 else {
            throw XCTSkip("Skipping base iPhone 11 component test on \(SnapshotDevice.current?.rawValue ?? "unknown device")")
        }

        struct MultiSelectContainer: View {
            @State var selection: Set<String> = ["News", "Sports"]
            var body: some View {
                NavigationStack {
                    MultiSelectView(
                        title: "Categories",
                        options: ["Animation", "Comedy", "Documentary", "News", "Sports"],
                        selection: $selection
                    )
                }
            }
        }

        SnapshotAssert.assertVariants(
            of: MultiSelectContainer(),
            on: .iPhone11,
            named: "multi-select-filter"
        )
    }

    // MARK: - Appearance Menu

    func testAppearanceMenu() throws {
        guard SnapshotDevice.current == .iPhone11 else {
            throw XCTSkip("Skipping base iPhone 11 component test on \(SnapshotDevice.current?.rawValue ?? "unknown device")")
        }

        let view = AppearanceMenu()
            .padding()

        SnapshotAssert.assertVariants(
            of: view,
            on: .iPhone11,
            named: "appearance-menu"
        )
    }

    // MARK: - Channel Section Header

    func testChannelSectionHeader() throws {
        guard SnapshotDevice.current == .iPhone11 else {
            throw XCTSkip("Skipping base iPhone 11 component test on \(SnapshotDevice.current?.rawValue ?? "unknown device")")
        }

        let view = ChannelSectionHeader(title: "Featured Channels")
            .padding()

        SnapshotAssert.assertVariants(
            of: view,
            on: .iPhone11,
            named: "channel-section-header"
        )
    }

    // MARK: - Favorite Button

    func testFavoriteButton() throws {
        guard SnapshotDevice.current == .iPhone11 else {
            throw XCTSkip("Skipping base iPhone 11 component test on \(SnapshotDevice.current?.rawValue ?? "unknown device")")
        }

        let view = HStack(spacing: 24) {
            FavoriteButton(isFavorite: true, action: {})
            FavoriteButton(isFavorite: false, action: {})
        }
        .padding()

        SnapshotAssert.assertVariants(
            of: view,
            on: .iPhone11,
            named: "favorite-button"
        )
    }

    // MARK: - Channel Logo

    func testChannelLogo() throws {
        guard SnapshotDevice.current == .iPhone11 else {
            throw XCTSkip("Skipping base iPhone 11 component test on \(SnapshotDevice.current?.rawValue ?? "unknown device")")
        }

        let view = HStack(spacing: 20) {
            ChannelLogo(url: nil)
            ChannelLogo(url: URL(string: "https://example.com/logo.png"))
        }
        .padding()

        SnapshotAssert.assertVariants(
            of: view,
            on: .iPhone11,
            named: "channel-logo"
        )
    }

    // MARK: - Developer Settings View

    func testDeveloperSettingsView() throws {
        guard SnapshotDevice.current == .iPhone11 else {
            throw XCTSkip("Skipping base iPhone 11 component test on \(SnapshotDevice.current?.rawValue ?? "unknown device")")
        }

        let view = NavigationStack {
            DeveloperSettingsView(buttonTitle: "Apply & Close", onContinue: {})
        }

        SnapshotAssert.assertVariants(
            of: view,
            on: .iPhone11,
            named: "developer-settings"
        )
    }
}
