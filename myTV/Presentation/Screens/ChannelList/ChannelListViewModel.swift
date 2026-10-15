import UIComponentsKit
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

    enum Grouping: String, CaseIterable, Identifiable {
        case name
        case country
        case category

        var id: String { rawValue }

        var title: String {
            switch self {
            case .name:
                return Localizable.App.Grouping.name
            case .country:
                return Localizable.App.Grouping.country
            case .category:
                return Localizable.App.Grouping.category
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
                return Localizable.Channel.Sort.Order.ascending
            case .descending:
                return Localizable.Channel.Sort.Order.descending
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
                return Localizable.Channel.Scope.all
            case .favorites:
                return Localizable.Channel.Scope.favorites
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
    @Published var gridAlert: GridAlert?

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

    @AppStorage("channelLayout")
    private var storedLayoutRaw = ChannelLayout.list.rawValue
    @Published private(set) var layout: ChannelLayout = .list

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
        layout = ChannelLayout(rawValue: storedLayoutRaw) ?? .list

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

    var offlineBannerViewModel: OfflineBannerViewModel {
        .default
    }

    var errorViewModel: ErrorViewModel {
        .generic
    }

    var navigationTitle: String {
        Localizable.App.name
    }

    var cancelButtonTitle: String {
        Localizable.App.cancel
    }

    var channelEmptyTitle: String {
        Localizable.Channel.Empty.title
    }

    var channelEmptyMessage: String {
        Localizable.Channel.Empty.message
    }

    var noResultsTitle: String {
        Localizable.Channel.No.Results.title
    }

    var noResultsMessage: String {
        Localizable.Channel.No.Results.message
    }

    var sortAndFilterSectionTitle: String {
        Localizable.Channel.Menu.Section.Sortandfilter.title
    }

    var groupByMenuTitle: String {
        Localizable.Channel.Menu.Section.GroupBy.title
    }

    var sectionSortingTitle: String {
        Localizable.Channel.Menu.Section.Section.title
    }

    var channelSortingTitle: String {
        Localizable.Channel.Menu.Section.Channel.title
    }

    var sortingMenuTitle: String {
        Localizable.Channel.Menu.Section.Sorting.title
    }

    var countriesFilterTitle: String {
        Localizable.Channel.Filter.countries
    }

    var categoriesFilterTitle: String {
        Localizable.Channel.Filter.categories
    }

    var filterMenuTitle: String {
        Localizable.Channel.Menu.Section.Filter.title
    }

    var actionsSectionTitle: String {
        Localizable.Channel.Menu.Section.actions
    }

    var clearCacheActionTitle: String {
        Localizable.Channel.Menu.Action.clearCache
    }

    var clearFiltersActionTitle: String {
        Localizable.Channel.Menu.Action.clearFilters
    }

    var removeFavoritesActionTitle: String {
        Localizable.Channel.Menu.Action.removeFavorites
    }

    var layoutSectionTitle: String {
        Localizable.Channel.Menu.Section.layout
    }

    var appearanceSectionTitle: String {
        Localizable.Channel.Menu.Section.appearance
    }

    var aboutSectionTitle: String {
        Localizable.Channel.Menu.Section.about
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

    var hasSelectedCountryFilters: Bool {
        !selectedCountries.isEmpty
    }

    var hasSelectedCategoryFilters: Bool {
        !selectedCategories.isEmpty
    }

    func shouldShowGrid(isAccessibilitySize: Bool) -> Bool {
        layout == .grid && !isAccessibilitySize
    }

    func sectionTitle(for key: String) -> String {
        switch grouping {
        case .country:
            return CountryDisplay.label(for: key)
        case .category:
            return CategoryDisplay.label(for: key)
        case .name:
            return key
        }
    }

    func countryDisplayName(_ value: String) -> String {
        CountryDisplay.label(for: value)
    }

    func categoryDisplayName(_ value: String) -> String {
        CategoryDisplay.label(for: value)
    }

    func countrySortKey(_ value: String) -> String {
        CountryDisplay.sortKey(for: value)
    }

    func categorySortKey(_ value: String) -> String {
        CategoryDisplay.sortKey(for: value)
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

    func setSectionSort(_ sortOrder: SortOrder) {
        guard sectionSort != sortOrder else { return }
        sectionSort = sortOrder
        haptics.selection()
    }

    func setChannelSort(_ sortOrder: SortOrder) {
        guard channelSort != sortOrder else { return }
        channelSort = sortOrder
        haptics.selection()
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

    func enforceListIfAccessibility(_ isAccessibilitySize: Bool) {
        guard isAccessibilitySize, layout == .grid else { return }
        storedLayoutRaw = ChannelLayout.list.rawValue
        gridAlert = .autoList
        layout = .list
    }

    func handleGridUnavailable() {
        gridAlert = .gridUnavailable
    }

    func clearGridAlert() {
        gridAlert = nil
    }

    var toolbarAlertTitle: String {
        switch pendingAction {
        case .clearCache:
            return Localizable.Channel.Alert.Clear.Cache.title
        case .clearFilters:
            return Localizable.Channel.Alert.Clear.Filters.title
        case .removeFavorites:
            return Localizable.Channel.Alert.Remove.Favorites.title
        case .none:
            return ""
        }
    }

    var toolbarAlertConfirm: String {
        switch pendingAction {
        case .clearCache:
            return Localizable.Channel.Alert.Clear.Cache.confirm
        case .clearFilters:
            return Localizable.Channel.Alert.Clear.Filters.confirm
        case .removeFavorites:
            return Localizable.Channel.Alert.Remove.Favorites.confirm
        case .none:
            return ""
        }
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
            let comparer: (Channel, Channel) -> Bool = { lhs, rhs in
                lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            }
            return channelSort == .ascending
                ? c.sorted(by: comparer)
                : c.sorted { comparer($1, $0) }
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

        let displayKey: (String) -> String = { key in
            switch grouping {
            case .country:
                return CountryDisplay.sortKey(for: key)
            case .category:
                return CategoryDisplay.sortKey(for: key)
            case .name:
                return key
            }
        }

        let keys = sectionSort == .ascending
            ? dict.keys.sorted { displayKey($0) < displayKey($1) }
            : dict.keys.sorted { displayKey($0) > displayKey($1) }

        return keys.map { ($0, sortChannels(dict[$0] ?? [])) }
    }
}
