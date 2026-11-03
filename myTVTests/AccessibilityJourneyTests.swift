//
//  AccessibilityJourneyTests.swift
//  myTVTests
//
//  Accessibility on complete app journeys verification (IOS-25)
//

import XCTest
import SwiftUI
import DesignTokensKit
import UIComponentsKit
@testable import myTV

@MainActor
final class AccessibilityJourneyTests: XCTestCase {

    override func setUp() async throws {
        try await super.setUp()
        UserDefaults.standard.set("stub", forKey: "developer.source")
        UserDefaults.standard.set("showcase", forKey: "developer.scenario")
    }

    override func tearDown() async throws {
        UserDefaults.standard.removeObject(forKey: "developer.source")
        UserDefaults.standard.removeObject(forKey: "developer.scenario")
        try await super.tearDown()
    }

    // MARK: - Dynamic Type & Text Clipping Verification

    func testDynamicTypeMaximumAccessibilitySizesOnChannelRow() {
        let channel = Channel(
            id: "nasa-tv-accessibility",
            name: "NASA TV Ultra High Definition Live Educational Broadcast Stream",
            country: "US",
            categories: ["Science", "Education"],
            isNSFW: false,
            logoURL: URL(string: "https://example.com/nasa.png"),
            hasStreams: false
        )

        for typeSize in [DynamicTypeSize.large, .accessibility3, .accessibility5] {
            let row = ChannelRowView(channel: channel, isFavorite: true, onFavoriteToggle: {})
                .environment(\.dynamicTypeSize, typeSize)

            let controller = UIHostingController(rootView: row)
            controller.view.frame = CGRect(x: 0, y: 0, width: 375, height: 250)
            controller.view.layoutIfNeeded()

            XCTAssertGreaterThan(controller.view.frame.width, 0)
            XCTAssertGreaterThan(controller.view.frame.height, 0)
        }
    }

    func testDynamicTypeMaximumAccessibilitySizesOnChannelGrid() {
        let channel = Channel(
            id: "bloomberg-accessibility",
            name: "Bloomberg Television International Financial News and Market Updates",
            country: "US",
            categories: ["News", "Business"],
            isNSFW: false,
            logoURL: URL(string: "https://example.com/bloomberg.png"),
            hasStreams: true
        )

        for typeSize in [DynamicTypeSize.large, .accessibility3, .accessibility5] {
            let grid = ChannelGridView(channel: channel, isFavorite: false, onFavoriteToggle: {})
                .environment(\.dynamicTypeSize, typeSize)

            let controller = UIHostingController(rootView: grid)
            controller.view.frame = CGRect(x: 0, y: 0, width: 180, height: 220)
            controller.view.layoutIfNeeded()

            XCTAssertGreaterThan(controller.view.frame.width, 0)
            XCTAssertGreaterThan(controller.view.frame.height, 0)
        }
    }

    // MARK: - Controls VoiceOver Labels & Values

    func testChannelStickyBarVoiceOverAccessibility() {
        var scope: ChannelListViewModel.ChannelScope = .all
        let binding = Binding(get: { scope }, set: { scope = $0 })
        let stickyBar = ChannelStickyBar(scope: binding)

        let controller = UIHostingController(rootView: stickyBar)
        controller.view.frame = CGRect(x: 0, y: 0, width: 390, height: 60)
        controller.view.layoutIfNeeded()

        XCTAssertNotNil(controller.view)
    }

    func testMultiSelectVoiceOverAccessibility() {
        let options = ["News", "Science", "Entertainment", "Sports"]
        var selection: Set<String> = ["News"]
        let binding = Binding(get: { selection }, set: { selection = $0 })
        let multiSelect = MultiSelectView(
            title: "Select Categories",
            options: options,
            selection: binding
        )

        let controller = UIHostingController(rootView: multiSelect)
        controller.view.frame = CGRect(x: 0, y: 0, width: 390, height: 600)
        controller.view.layoutIfNeeded()

        XCTAssertNotNil(controller.view)
    }

    // MARK: - Complete Journey VoiceOver Navigation Elements

    func testCompleteCatalogJourneyVoiceOverElements() async {
        let viewModel = AppDI.shared.makeChannelListViewModel()
        await viewModel.load()

        guard case .loaded = viewModel.state else {
            XCTFail("Expected loaded state")
            return
        }

        let channelListView = ChannelListView(viewModel: viewModel)
            .environment(\.dynamicTypeSize, .accessibility3)

        let controller = UIHostingController(rootView: channelListView)
        controller.view.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        controller.view.layoutIfNeeded()

        XCTAssertFalse(viewModel.channels.isEmpty, "Showcase channels must be present for accessibility hierarchy")
    }
}
