import XCTest
import SwiftUI
import SnapshotTestKit
@testable import myTV

@MainActor
final class ChannelListSnapshotTests: XCTestCase {

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

    // MARK: - Base Device: iPhone 11 (iOS 26.5)

    func testChannelListOnBaseDevice_iPhone11() async throws {
        guard SnapshotDevice.current == .iPhone11 else {
            throw XCTSkip("Skipping base iPhone 11 tests when running on \(SnapshotDevice.current?.rawValue ?? "unknown device")")
        }

        let viewModel = AppDI.shared.makeChannelListViewModel()
        await viewModel.load()
        let view = ChannelListView(viewModel: viewModel)

        // Tests all 3 ways: Light, Dark, and Accessibility on base iPhone 11
        SnapshotAssert.assertVariants(
            of: view,
            on: .iPhone11,
            named: "catalog"
        )
    }

    func testChannelListEmptyScenario_iPhone11() async throws {
        guard SnapshotDevice.current == .iPhone11 else {
            throw XCTSkip("Skipping base iPhone 11 tests when running on \(SnapshotDevice.current?.rawValue ?? "unknown device")")
        }

        UserDefaults.standard.set("stub", forKey: "developer.source")
        UserDefaults.standard.set("empty", forKey: "developer.scenario")

        let viewModel = AppDI.shared.makeChannelListViewModel()
        await viewModel.load()
        let view = ChannelListView(viewModel: viewModel)

        SnapshotAssert.assertVariants(
            of: view,
            on: .iPhone11,
            named: "catalog-empty"
        )
    }

    func testChannelListOfflineScenario_iPhone11() async throws {
        guard SnapshotDevice.current == .iPhone11 else {
            throw XCTSkip("Skipping base iPhone 11 tests when running on \(SnapshotDevice.current?.rawValue ?? "unknown device")")
        }

        UserDefaults.standard.set("stub", forKey: "developer.source")
        UserDefaults.standard.set("offline", forKey: "developer.scenario")

        let viewModel = AppDI.shared.makeChannelListViewModel()
        await viewModel.load()
        let view = ChannelListView(viewModel: viewModel)

        SnapshotAssert.assertVariants(
            of: view,
            on: .iPhone11,
            named: "catalog-offline"
        )
    }

    // MARK: - Foldable / Dual Aspect Device: iPhone Duo (iOS 27.1)

    func testChannelListOnFoldable_iPhoneDuo() async throws {
        guard SnapshotDevice.current == .iPhoneDuo else {
            throw XCTSkip("Skipping iPhone Duo tests when running on \(SnapshotDevice.current?.rawValue ?? "unknown device")")
        }

        let viewModel = AppDI.shared.makeChannelListViewModel()
        await viewModel.load()
        let view = ChannelListView(viewModel: viewModel)

        // Tests all 3 ways: Light, Dark, and Accessibility on iPhone Duo
        SnapshotAssert.assertVariants(
            of: view,
            on: .iPhoneDuo,
            named: "catalog"
        )
    }

    func testChannelListEmptyScenario_iPhoneDuo() async throws {
        guard SnapshotDevice.current == .iPhoneDuo else {
            throw XCTSkip("Skipping iPhone Duo tests when running on \(SnapshotDevice.current?.rawValue ?? "unknown device")")
        }

        UserDefaults.standard.set("stub", forKey: "developer.source")
        UserDefaults.standard.set("empty", forKey: "developer.scenario")

        let viewModel = AppDI.shared.makeChannelListViewModel()
        await viewModel.load()
        let view = ChannelListView(viewModel: viewModel)

        SnapshotAssert.assertVariants(
            of: view,
            on: .iPhoneDuo,
            named: "catalog-empty"
        )
    }

    func testChannelListOfflineScenario_iPhoneDuo() async throws {
        guard SnapshotDevice.current == .iPhoneDuo else {
            throw XCTSkip("Skipping iPhone Duo tests when running on \(SnapshotDevice.current?.rawValue ?? "unknown device")")
        }

        UserDefaults.standard.set("stub", forKey: "developer.source")
        UserDefaults.standard.set("offline", forKey: "developer.scenario")

        let viewModel = AppDI.shared.makeChannelListViewModel()
        await viewModel.load()
        let view = ChannelListView(viewModel: viewModel)

        SnapshotAssert.assertVariants(
            of: view,
            on: .iPhoneDuo,
            named: "catalog-offline"
        )
    }

    // MARK: - Standard Tablet Device: iPad (A16) (iPadOS 27.0)

    func testChannelListOnTablet_iPad() async throws {
        guard SnapshotDevice.current == .iPad else {
            throw XCTSkip("Skipping iPad tests when running on \(SnapshotDevice.current?.rawValue ?? "unknown device")")
        }

        let viewModel = AppDI.shared.makeChannelListViewModel()
        await viewModel.load()
        let view = ChannelListView(viewModel: viewModel)

        // Tests all 3 ways: Light, Dark, and Accessibility on Standard iPad
        SnapshotAssert.assertVariants(
            of: view,
            on: .iPad,
            named: "catalog"
        )
    }

    func testChannelListEmptyScenario_iPad() async throws {
        guard SnapshotDevice.current == .iPad else {
            throw XCTSkip("Skipping iPad tests when running on \(SnapshotDevice.current?.rawValue ?? "unknown device")")
        }

        UserDefaults.standard.set("stub", forKey: "developer.source")
        UserDefaults.standard.set("empty", forKey: "developer.scenario")

        let viewModel = AppDI.shared.makeChannelListViewModel()
        await viewModel.load()
        let view = ChannelListView(viewModel: viewModel)

        SnapshotAssert.assertVariants(
            of: view,
            on: .iPad,
            named: "catalog-empty"
        )
    }

    func testChannelListOfflineScenario_iPad() async throws {
        guard SnapshotDevice.current == .iPad else {
            throw XCTSkip("Skipping iPad tests when running on \(SnapshotDevice.current?.rawValue ?? "unknown device")")
        }

        UserDefaults.standard.set("stub", forKey: "developer.source")
        UserDefaults.standard.set("offline", forKey: "developer.scenario")

        let viewModel = AppDI.shared.makeChannelListViewModel()
        await viewModel.load()
        let view = ChannelListView(viewModel: viewModel)

        SnapshotAssert.assertVariants(
            of: view,
            on: .iPad,
            named: "catalog-offline"
        )
    }
}
