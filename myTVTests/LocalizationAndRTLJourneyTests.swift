//
//  LocalizationAndRTLJourneyTests.swift
//  myTVTests
//
//  Verification of localized authentication, recoverable errors, and RTL journeys (IOS-26)
//

import XCTest
import SwiftUI
import DesignTokensKit
import UIComponentsKit
import LocalizationKit
import AuthKit
import AuthKitUI
@testable import myTV

@MainActor
final class LocalizationAndRTLJourneyTests: XCTestCase {

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

    // MARK: - Localized Copy Verification Across Locales

    func testLocalizedAuthAndAccountCopyAcrossLocales() {
        let locales = ["en", "fr", "ar"]

        for localeCode in locales {
            let controller = LocalizationController(initialLocale: Locale(identifier: localeCode))

            let signIn = L10n.Auth.signIn(using: controller)
            let email = L10n.Auth.email(using: controller)
            let password = L10n.Auth.password(using: controller)
            let deleteAccount = L10n.Account.deleteAccount(using: controller)
            let signOut = L10n.Account.signOut(using: controller)

            XCTAssertFalse(signIn.isEmpty, "Sign in string should not be empty for \(localeCode)")
            XCTAssertFalse(email.isEmpty, "Email string should not be empty for \(localeCode)")
            XCTAssertFalse(password.isEmpty, "Password string should not be empty for \(localeCode)")
            XCTAssertFalse(deleteAccount.isEmpty, "Delete account should not be empty for \(localeCode)")
            XCTAssertFalse(signOut.isEmpty, "Sign out should not be empty for \(localeCode)")

            if localeCode == "ar" {
                XCTAssertTrue(controller.isRightToLeft, "Arabic locale must be detected as right-to-left")
            } else {
                XCTAssertFalse(controller.isRightToLeft, "\(localeCode) locale must be detected as left-to-right")
            }
        }
    }

    // MARK: - AppAuthGate Integration with LocalizationController

    func testAppAuthGateWithArabicLocalizationAndRTL() {
        let arabicController = LocalizationController(initialLocale: Locale(identifier: "ar"))
        var signedOut = false

        let gateView = AppAuthGate(
            brand: .myTV,
            localizer: arabicController,
            onSignedOut: { signedOut = true },
            content: { _, _ in
                Text("Authenticated Channel List")
            }
        )
        .environment(\.layoutDirection, arabicController.isRightToLeft ? .rightToLeft : .leftToRight)

        let gateHost = UIHostingController(rootView: gateView)
        gateHost.view.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        gateHost.view.layoutIfNeeded()

        XCTAssertNotNil(gateHost.view)
        XCTAssertGreaterThan(gateHost.view.frame.width, 0)
        XCTAssertFalse(signedOut)
    }

    // MARK: - RTL Layout Direction on Channel Views

    func testChannelRowAndGridUnderRTL() {
        let channel = Channel(
            id: "arabic-news-channel",
            name: "قناة الأخبار العالمية المباشرة",
            country: "AE",
            categories: ["أخبار", "ثقافة"],
            isNSFW: false,
            logoURL: URL(string: "https://example.com/logo.png"),
            hasStreams: true
        )

        let rtlRow = ChannelRowView(channel: channel, isFavorite: true, onFavoriteToggle: {})
            .environment(\.layoutDirection, .rightToLeft)
            .environment(\.dynamicTypeSize, .accessibility3)

        let rowHost = UIHostingController(rootView: rtlRow)
        rowHost.view.frame = CGRect(x: 0, y: 0, width: 375, height: 250)
        rowHost.view.layoutIfNeeded()

        XCTAssertNotNil(rowHost.view)
        XCTAssertGreaterThan(rowHost.view.frame.width, 0)
        XCTAssertGreaterThan(rowHost.view.frame.height, 0)

        let rtlGrid = ChannelGridView(channel: channel, isFavorite: false, onFavoriteToggle: {})
            .environment(\.layoutDirection, .rightToLeft)
            .environment(\.dynamicTypeSize, .accessibility3)

        let gridHost = UIHostingController(rootView: rtlGrid)
        gridHost.view.frame = CGRect(x: 0, y: 0, width: 180, height: 220)
        gridHost.view.layoutIfNeeded()

        XCTAssertNotNil(gridHost.view)
        XCTAssertGreaterThan(gridHost.view.frame.width, 0)
    }

    // MARK: - ChannelStickyBar and Navigation Under RTL

    func testChannelStickyBarUnderRTL() {
        var scope: ChannelListViewModel.ChannelScope = .all
        let binding = Binding(get: { scope }, set: { scope = $0 })
        let stickyBar = ChannelStickyBar(scope: binding)
            .environment(\.layoutDirection, .rightToLeft)

        let barHost = UIHostingController(rootView: stickyBar)
        barHost.view.frame = CGRect(x: 0, y: 0, width: 390, height: 60)
        barHost.view.layoutIfNeeded()

        XCTAssertNotNil(barHost.view)
        XCTAssertGreaterThan(barHost.view.frame.width, 0)
    }

    // MARK: - Recoverable Error States Under RTL

    func testRecoverableErrorViewsUnderRTL() {
        let errorViewModel = ErrorViewModel(title: "تعذر تحميل القنوات", retryTitle: "إعادة المحاولة")
        let errorView = ErrorView(viewModel: errorViewModel, message: "تحقق من اتصالك بالإنترنت وحاول مرة أخرى") {
            // retry
        }
        .environment(\.layoutDirection, .rightToLeft)
        .environment(\.dynamicTypeSize, .accessibility3)

        let errorHost = UIHostingController(rootView: errorView)
        errorHost.view.frame = CGRect(x: 0, y: 0, width: 390, height: 600)
        errorHost.view.layoutIfNeeded()

        XCTAssertNotNil(errorHost.view)
        XCTAssertGreaterThan(errorHost.view.frame.height, 0)

        let bannerViewModel = OfflineBannerViewModel(message: "أنت غير متصل بالإنترنت حالياً")
        let bannerView = OfflineBanner(viewModel: bannerViewModel)
            .environment(\.layoutDirection, .rightToLeft)
            .environment(\.dynamicTypeSize, .accessibility3)

        let bannerHost = UIHostingController(rootView: bannerView)
        bannerHost.view.frame = CGRect(x: 0, y: 0, width: 390, height: 80)
        bannerHost.view.layoutIfNeeded()

        XCTAssertNotNil(bannerHost.view)
        XCTAssertGreaterThan(bannerHost.view.frame.width, 0)
    }
}
