import LocalizationKit
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
    
    var offlineBannerViewModel: OfflineBannerViewModel {
        .default
    }

    var navigationTitle: String {
        String(\MyTVStrings.aboutTitle)
    }

    var invalidLinkAlertTitle: String {
        String(\MyTVStrings.aboutAlertErrorTitle)
    }

    var invalidLinkAlertOk: String {
        String(\MyTVStrings.aboutAlertErrorOk)
    }

    var invalidLinkAlertMessage: String {
        String(\MyTVStrings.aboutAlertErrorInvalidLink)
    }

    var layoutMenuSectionTitle: String {
        String(\MyTVStrings.layoutMenuTitle)
    }

    var appearanceMenuSectionTitle: String {
        String(\MyTVStrings.appearanceMenuTitle)
    }

    var appInfoTitle: String {
        String(\MyTVStrings.aboutAppInfoTitle)
    }

    var appName: String {
        String(\MyTVStrings.aboutAppName)
    }

    var appVersionPrefix: String {
        String(\MyTVStrings.aboutAppVersionPrefix)
    }

    var disclaimerTitle: String {
        String(\MyTVStrings.aboutDisclaimerTitle)
    }

    var disclaimerText: String {
        String(\MyTVStrings.aboutDisclaimerText)
    }

    var socialTitle: String {
        String(\MyTVStrings.aboutSocialTitle)
    }

    var layoutMenuTitle: String {
        String(\MyTVStrings.layoutTitle)
    }

    func title(for layout: ChannelLayout) -> String {
        switch layout {
        case .list:
            return String(\MyTVStrings.layoutList)
        case .grid:
            return String(\MyTVStrings.layoutGrid)
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
            return String(\MyTVStrings.layoutAutoListTitle)
        case .gridUnavailable:
            return String(\MyTVStrings.layoutUnavailableTitle)
        case .none:
            return ""
        }
    }

    var gridAlertMessage: String {
        switch gridAlert {
        case .autoList:
            return String(\MyTVStrings.layoutAutoListMessage)
        case .gridUnavailable:
            return String(\MyTVStrings.layoutUnavailableMessage)
        case .none:
            return ""
        }
    }

    var gridAlertOk: String {
        switch gridAlert {
        case .autoList:
            return String(\MyTVStrings.layoutAutoListOk)
        case .gridUnavailable:
            return String(\MyTVStrings.layoutUnavailableOk)
        case .none:
            return String(\MyTVStrings.layoutUnavailableOk)
        }
    }

    func selectionHaptic() {
        haptics.selection()
    }
}
