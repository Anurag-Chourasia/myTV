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
    @AppStorage("channelLayout") private(set) var layout: ChannelLayout = .list
    // MARK: - Dependencies
    private let reachability: ReachabilityService
    private let haptics: HapticService
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init
    init(
        reachability: ReachabilityService,
        haptics: HapticService,
    ) {
        self.reachability = reachability
        self.haptics = haptics
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
}
