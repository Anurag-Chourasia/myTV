//
//  ChannelListViewModel.swift
//  myTV
//
//  Created by Anurag Chourasia on 23/01/26.
//

import Combine
import UIKit
import SwiftUI

@MainActor
final class ChannelListViewModel: ObservableObject {

    // MARK: - UI State
    enum UIState {
        case loading
        case loaded
        case empty
        case error(String)
    }

    enum Grouping: String, CaseIterable, Identifiable {
        case name
        case country
        case category

        var id: String { rawValue }

        var title: String {
            switch self {
            case .name:
                return L10n.App.Grouping.name
            case .country:
                return L10n.App.Grouping.country
            case .category:
                return L10n.App.Grouping.category
            }
        }
    }

    enum SortOrder: String, CaseIterable, Identifiable {
        case ascending
        case descending

        var id: String { rawValue }

        var title: String {
            switch self {
            case .ascending:
                return L10n.Channel.Sort.Order.ascending
            case .descending:
                return L10n.Channel.Sort.Order.descending
            }
        }
    }

    enum ChannelScope: String, CaseIterable, Identifiable {
        case all
        case favorites

        var id: String { rawValue }

        var title: String {
            switch self {
            case .all:
                return L10n.Channel.Scope.all
            case .favorites:
                return L10n.Channel.Scope.favorites
            }
        }
    }

    enum ToolbarAction {
        case clearCache
        case clearFilters
        case removeFavorites
    }

    // MARK: - Published
    @Published private(set) var state: UIState = .loading
    @Published private(set) var groupedResult: [(String, [Channel])] = []
    @Published private(set) var channels: [Channel] = []
    @Published private(set) var debouncedSearchText = ""

    @Published var searchText = ""
    @Published var channelScope: ChannelScope = .all
    @Published var selectedCountries: Set<String> = []
    @Published var selectedCategories: Set<String> = []
    @Published var favoriteChannelIDs: Set<String> = []
    @Published var showOfflineBanner = false
    @Published var showAlertDialog = false

    @Published var grouping: Grouping = .name {
        didSet { storedGroupingRaw = grouping.rawValue }
    }
    @Published var sectionSort: SortOrder = .ascending {
        didSet { storedSectionSortRaw = sectionSort.rawValue }
    }
    @Published var channelSort: SortOrder = .ascending {
        didSet { storedChannelSortRaw = channelSort.rawValue }
    }

    private(set) var pendingAction: ToolbarAction?

    // MARK: - AppStorage
    @AppStorage("channelGrouping")
    private var storedGroupingRaw = Grouping.name.rawValue

    @AppStorage("sectionSort")
    private var storedSectionSortRaw = SortOrder.ascending.rawValue

    @AppStorage("channelSort")
    private var storedChannelSortRaw = SortOrder.ascending.rawValue

    @AppStorage("channelLayout") private(set) var layout: ChannelLayout = .list

    // MARK: - Dependencies
    private let fetchChannels: FetchChannelsUseCase
    private let reachability: ReachabilityService
    private let haptics: HapticService
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init
    init(
        fetchChannels: DefaultFetchChannelsUseCase,
        reachability: ReachabilityService,
        haptics: HapticService
    ) {
        self.fetchChannels = fetchChannels
        self.reachability = reachability
        self.haptics = haptics

        grouping = Grouping(rawValue: storedGroupingRaw) ?? .name
        sectionSort = SortOrder(rawValue: storedSectionSortRaw) ?? .ascending
        channelSort = SortOrder(rawValue: storedChannelSortRaw) ?? .ascending

        observeReachability()
        setupDebouncedSearch()
        setupFilteringPipeline()
    }

    // MARK: - Load
    func load() async {
        state = .loading
        do {
            let result = try await fetchChannels.execute()
            channels = result
            state = result.isEmpty ? .empty : .loaded
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    // MARK: - Favorites
    func toggleFavorite(_ id: String) {
        if favoriteChannelIDs.contains(id) {
            favoriteChannelIDs.remove(id)
            haptics.impact(.light)
        } else {
            favoriteChannelIDs.insert(id)
            haptics.impact(.medium)
        }
    }

    // MARK: - Derived
    var isFilteredEmpty: Bool {
        groupedResult.allSatisfy { $0.1.isEmpty }
    }

    var allCountries: [String] {
        Array(Set(channels.map(\.country))).sorted()
    }

    var allCategories: [String] {
        Array(Set(channels.flatMap(\.categories))).sorted()
    }

    // MARK: - Toolbar Actions
    func requestAction(_ action: ToolbarAction) {
        pendingAction = action
        showAlertDialog = true
    }

    func confirmAction() {
        guard let action = pendingAction else { return }

        switch action {
        case .clearCache:
            Task { await clearCache() }
        case .clearFilters:
            clearAllPreferences()
        case .removeFavorites:
            removeAllFavorites()
        }

        resetDialog()
    }

    func cancelAction() {
        resetDialog()
    }

    private func resetDialog() {
        pendingAction = nil
        showAlertDialog = false
    }

    // MARK: - Mutations
    func setGrouping(_ grouping: Grouping) {
        guard self.grouping != grouping else { return }
        self.grouping = grouping
        haptics.selection()
    }

    func setScope(_ scope: ChannelScope) {
        guard channelScope != scope else { return }
        channelScope = scope
        haptics.selection()
    }

    func clearAllPreferences() {
        grouping = .name
        sectionSort = .ascending
        channelSort = .ascending
        selectedCountries.removeAll()
        selectedCategories.removeAll()
        haptics.notification(.warning)
    }

    func removeAllFavorites() {
        favoriteChannelIDs.removeAll()
        haptics.notification(.error)
    }

    func clearCache() async {
        haptics.notification(.warning)
        state = .loading
        channels = []
        groupedResult = []
        fetchChannels.clearCache()
        DefaultImageCache.shared.clear()
        await load()
    }
}

// MARK: - Private
private extension ChannelListViewModel {

    func observeReachability() {
        reachability.isOnlinePublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] online in
                self?.showOfflineBanner = !online
            }
            .store(in: &cancellables)
    }

    func setupDebouncedSearch() {
        $searchText
            .debounce(for: .milliseconds(200), scheduler: RunLoop.main)
            .removeDuplicates()
            .assign(to: &$debouncedSearchText)
    }

    func setupFilteringPipeline() {
        let base = Publishers.CombineLatest4(
            $channels,
            $debouncedSearchText,
            $selectedCountries,
            $selectedCategories
        )

        let extras = Publishers.CombineLatest3(
            $grouping,
            $favoriteChannelIDs,
            $channelScope
        )

        let sorting = Publishers.CombineLatest(
            $sectionSort,
            $channelSort
        )

        Publishers.CombineLatest3(base, extras, sorting)
            .map { base, extras, sorting in
                Self.compute(
                    channels: base.0,
                    search: base.1,
                    countries: base.2,
                    categories: base.3,
                    grouping: extras.0,
                    favorites: extras.1,
                    scope: extras.2,
                    sectionSort: sorting.0,
                    channelSort: sorting.1
                )
            }
            .assign(to: &$groupedResult)
    }

    static func compute(
        channels: [Channel],
        search: String,
        countries: Set<String>,
        categories: Set<String>,
        grouping: Grouping,
        favorites: Set<String>,
        scope: ChannelScope,
        sectionSort: SortOrder,
        channelSort: SortOrder
    ) -> [(String, [Channel])] {

        let filtered = channels.filter {
            (scope == .all || favorites.contains($0.id)) &&
            (search.isEmpty || $0.name.localizedCaseInsensitiveContains(search)) &&
            (countries.isEmpty || countries.contains($0.country)) &&
            (categories.isEmpty || !Set($0.categories).isDisjoint(with: categories))
        }

        func sortChannels(_ c: [Channel]) -> [Channel] {
            channelSort == .ascending
            ? c.sorted { $0.name < $1.name }
            : c.sorted { $0.name > $1.name }
        }

        var dict: [String: [Channel]] = [:]

        switch grouping {
        case .name:
            dict = Dictionary(grouping: filtered) { String($0.name.prefix(1)).uppercased() }
        case .country:
            dict = Dictionary(grouping: filtered) { $0.country }
        case .category:
            for channel in filtered {
                for category in channel.categories {
                    dict[category, default: []].append(channel)
                }
            }
        }

        let keys = sectionSort == .ascending
            ? dict.keys.sorted()
            : dict.keys.sorted(by: >)

        return keys.map { ($0, sortChannels(dict[$0] ?? [])) }
    }
}
