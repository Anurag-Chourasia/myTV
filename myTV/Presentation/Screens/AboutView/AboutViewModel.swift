import UIComponentsKit
//
//  AboutViewModel.swift
//  myTV
//
//  Created by Anurag Chourasia on 23/01/26.
//

import Combine
import SwiftUI

@MainActor
final class AboutViewModel: ObservableObject {

    // MARK: - Published UI State
    @Published var showOfflineBanner = false
    @Published var showAlert = false
    @Published var gridAlert: GridAlert?
    @AppStorage("channelLayout")
    private var storedLayoutRaw = ChannelLayout.list.rawValue
    @Published private(set) var layout: ChannelLayout = .list
    
    enum GridAlert: Identifiable {
        case autoList
        case gridUnavailable

        var id: String {
            switch self {
            case .autoList: return "autoList"
            case .gridUnavailable: return "gridUnavailable"
            }
        }
    }
    // MARK: - Dependencies
    private let reachability: ReachabilityService
    private let haptics: HapticService
    private var cancellables = Set<AnyCancellable>()
    
    var socialLinks: [SocialLink] {
        [
            .init(
                title: Localizable.About.Social.github,
                icon: Localizable.About.Social.github,
                url: URL(string: Localizable.About.Social.Github.url)!
            ),
            .init(
                title: Localizable.About.Social.linkedin,
                icon: Localizable.About.Social.linkedin,
                url: URL(string: Localizable.About.Social.Linkedin.url)!
            ),
            .init(
                title: Localizable.About.Social.email,
                icon: Localizable.About.Social.gmail,
                url: URL(string: Localizable.About.Social.Email.url)!
            ),
            .init(
                title: Localizable.About.Social.cv,
                icon: Localizable.About.Social.cv,
                url: URL(string: Localizable.About.Social.Cv.url)!
            )
        ]
    }

    var offlineBannerViewModel: OfflineBannerViewModel {
        .default
    }

    var navigationTitle: String {
        Localizable.About.title
    }

    var invalidLinkAlertTitle: String {
        Localizable.About.Alert.Error.title
    }

    var invalidLinkAlertOk: String {
        Localizable.About.Alert.Error.ok
    }

    var invalidLinkAlertMessage: String {
        Localizable.About.Alert.Error.invalidLink
    }

    var layoutMenuSectionTitle: String {
        Localizable.About.Menu.layout
    }

    var appearanceMenuSectionTitle: String {
        Localizable.About.Menu.appearance
    }

    var developerImageName: String {
        Localizable.App.Developer.firstName
    }

    var developerName: String {
        Localizable.About.Developer.name
    }

    var developerRole: String {
        Localizable.About.Developer.role
    }

    var appInfoTitle: String {
        Localizable.About.App.Info.title
    }

    var appName: String {
        Localizable.About.App.name
    }

    var appVersionPrefix: String {
        Localizable.About.App.Version.prefix
    }

    var disclaimerTitle: String {
        Localizable.About.Disclaimer.title
    }

    var disclaimerText: String {
        Localizable.About.Disclaimer.text
    }

    var socialTitle: String {
        Localizable.About.Social.title
    }

    var layoutMenuTitle: String {
        Localizable.Channel.Layout.title
    }

    func title(for layout: ChannelLayout) -> String {
        switch layout {
        case .list:
            return Localizable.Channel.Layout.list
        case .grid:
            return Localizable.Channel.Layout.grid
        }
    }

    // MARK: - Init
    init(
        reachability: ReachabilityService,
        haptics: HapticService,
    ) {
        self.reachability = reachability
        self.haptics = haptics
        layout = ChannelLayout(rawValue: storedLayoutRaw) ?? .list
        observeReachability()
    }

    // MARK: - Reachability
    private func observeReachability() {
        reachability.isOnlinePublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] isOnline in
                self?.showOfflineBanner = !isOnline
            }
            .store(in: &cancellables)
    }

    func handleInvalidLink() {
        showAlert = true
    }

    func enforceListIfAccessibility(_ isAccessibilitySize: Bool) {
        guard isAccessibilitySize, layout != .list else { return }
        storedLayoutRaw = ChannelLayout.list.rawValue
        layout = .list
        gridAlert = .autoList
    }

    func handleGridUnavailable() {
        gridAlert = .gridUnavailable
    }

    func clearGridAlert() {
        gridAlert = nil
    }

    func setLayout(_ layout: ChannelLayout) {
        guard self.layout != layout else { return }
        self.layout = layout
        storedLayoutRaw = layout.rawValue
        haptics.selection()
    }

    func syncLayoutFromStorage() {
        let persisted = ChannelLayout(rawValue: storedLayoutRaw) ?? .list
        if layout != persisted {
            layout = persisted
        }
    }

    func refreshAccessibilityLayoutState(isAccessibilitySize: Bool) {
        syncLayoutFromStorage()
        enforceListIfAccessibility(isAccessibilitySize)
    }

    func shouldUseGridLayout(isAccessibilitySize: Bool) -> Bool {
        layout == .grid && !isAccessibilitySize
    }

    var gridAlertTitle: String {
        switch gridAlert {
        case .autoList:
            return Localizable.Channel.Layout.Grid.AutoList.title
        case .gridUnavailable:
            return Localizable.Channel.Layout.Grid.Unavailable.title
        case .none:
            return ""
        }
    }

    var gridAlertMessage: String {
        switch gridAlert {
        case .autoList:
            return Localizable.Channel.Layout.Grid.AutoList.message
        case .gridUnavailable:
            return Localizable.Channel.Layout.Grid.Unavailable.message
        case .none:
            return ""
        }
    }

    var gridAlertOk: String {
        switch gridAlert {
        case .autoList:
            return Localizable.Channel.Layout.Grid.AutoList.ok
        case .gridUnavailable:
            return Localizable.Channel.Layout.Grid.Unavailable.ok
        case .none:
            return Localizable.Channel.Layout.Grid.Unavailable.ok
        }
    }
}

struct SocialLink: Identifiable {
    let title: String
    let icon: String
    let url: URL

    var id: String { title }
}
