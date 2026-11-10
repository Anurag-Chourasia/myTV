import LocalizationKit
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

    typealias Grouping = ChannelGrouping
    typealias SortOrder = ChannelSortOrder
    typealias ChannelScope = myTV.ChannelScope

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
    @Published var hideUnavailableStreams = false
    @Published private(set) var favoriteChannelIDs: Set<String> = [] {
        didSet { favorites.save(favoriteChannelIDs) }
    }
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
    private let fetchChannels: any FetchChannelsUseCase
    private let filterChannels: any FilterChannelsUseCase
    private let manageCache: (any ManageChannelCacheUseCase)?
    private let reachability: ReachabilityService
    private let favorites: any FavoriteChannelStoring
    let haptics: HapticService
    private let imageCache: any ImageCache
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init
    init(
        fetchChannels: any FetchChannelsUseCase,
        filterChannels: any FilterChannelsUseCase = DefaultFilterChannelsUseCase(),
        manageCache: (any ManageChannelCacheUseCase)? = nil,
        reachability: ReachabilityService,
        haptics: HapticService,
        favorites: any FavoriteChannelStoring = InMemoryFavoriteChannelStore(),
        imageCache: any ImageCache = EmptyImageCache()
    ) {
        self.fetchChannels = fetchChannels
        self.filterChannels = filterChannels
        self.manageCache = manageCache
        self.reachability = reachability
        self.haptics = haptics
        self.favorites = favorites
        self.imageCache = imageCache
        favoriteChannelIDs = favorites.load()

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
        String(\MyTVStrings.appName)
    }

    var cancelButtonTitle: String {
        LocalizationController.shared.string("app.cancel")
    }

    var channelEmptyTitle: String {
        String(\MyTVStrings.noChannelsTitle)
    }

    var channelEmptyMessage: String {
        String(\MyTVStrings.noChannelsMessage)
    }

    var noResultsTitle: String {
        String(\MyTVStrings.noResultsTitle)
    }

    var noResultsMessage: String {
        String(\MyTVStrings.noResultsMessage)
    }

    var sortAndFilterSectionTitle: String {
        String(\MyTVStrings.sortAndFilterTitle)
    }

    var groupByMenuTitle: String {
        String(\MyTVStrings.sectionGroupBy)
    }

    var sectionSortingTitle: String {
        String(\MyTVStrings.sectionTitle)
    }

    var channelSortingTitle: String {
        String(\MyTVStrings.channelTitle)
    }

    var sortingMenuTitle: String {
        String(\MyTVStrings.sectionSorting)
    }

    var countriesFilterTitle: String {
        String(\MyTVStrings.countries)
    }

    var categoriesFilterTitle: String {
        String(\MyTVStrings.categories)
    }

    var filterMenuTitle: String {
        String(\MyTVStrings.sectionFilter)
    }

    var actionsSectionTitle: String {
        String(\MyTVStrings.actionsTitle)
    }

    var clearCacheActionTitle: String {
        String(\MyTVStrings.clearCacheAction)
    }

    var clearFiltersActionTitle: String {
        String(\MyTVStrings.clearFiltersAction)
    }

    var removeFavoritesActionTitle: String {
        String(\MyTVStrings.removeFavoritesAction)
    }

    var layoutSectionTitle: String {
        String(\MyTVStrings.layoutMenuTitle)
    }

    var appearanceSectionTitle: String {
        String(\MyTVStrings.appearanceMenuTitle)
    }

    var aboutSectionTitle: String {
        String(\MyTVStrings.aboutMenuTitle)
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
        hideUnavailableStreams = false
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
        try? await manageCache?.clearCache()
        imageCache.clear()
        await load()
    }

    func selectionHaptic() {
        haptics.selection()
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
            return String(\MyTVStrings.clearCacheAlertTitle)
        case .clearFilters:
            return String(\MyTVStrings.clearFiltersAlertTitle)
        case .removeFavorites:
            return String(\MyTVStrings.removeFavoritesAlertTitle)
        case .none:
            return ""
        }
    }

    var toolbarAlertConfirm: String {
        switch pendingAction {
        case .clearCache:
            return String(\MyTVStrings.clearCacheConfirm)
        case .clearFilters:
            return String(\MyTVStrings.clearFiltersConfirm)
        case .removeFavorites:
            return String(\MyTVStrings.removeFavoritesConfirm)
        case .none:
            return ""
        }
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

        let extras = Publishers.CombineLatest4(
            $grouping,
            $favoriteChannelIDs,
            $channelScope,
            $hideUnavailableStreams
        )

        let sorting = Publishers.CombineLatest(
            $sectionSort,
            $channelSort
        )

        let filter = filterChannels

        Publishers.CombineLatest3(base, extras, sorting)
            .map { base, extras, sorting in
                filter.execute(
                    channels: base.0,
                    query: base.1,
                    categories: base.3,
                    countries: base.2,
                    scope: extras.2,
                    favorites: extras.1,
                    hideUnavailableStreams: extras.3,
                    grouping: extras.0,
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
        hideUnavailableStreams: Bool,
        sectionSort: SortOrder,
        channelSort: SortOrder
    ) -> [(String, [Channel])] {
        DefaultFilterChannelsUseCase().execute(
            channels: channels,
            query: search,
            categories: categories,
            countries: countries,
            scope: scope,
            favorites: favorites,
            hideUnavailableStreams: hideUnavailableStreams,
            grouping: grouping,
            sectionSort: sectionSort,
            channelSort: channelSort
        )
    }
}

extension ChannelGrouping {
    var title: String {
        switch self {
        case .name:
            return String(\MyTVStrings.groupingName)
        case .country:
            return String(\MyTVStrings.groupingCountry)
        case .category:
            return String(\MyTVStrings.groupingCategory)
        }
    }
}

extension ChannelSortOrder {
    var title: String {
        switch self {
        case .ascending:
            return String(\MyTVStrings.sortAscending)
        case .descending:
            return String(\MyTVStrings.sortDescending)
        }
    }
}

extension ChannelScope {
    var title: String {
        switch self {
        case .all:
            return String(\MyTVStrings.allChannels)
        case .favorites:
            return String(\MyTVStrings.favorites)
        }
    }
}
