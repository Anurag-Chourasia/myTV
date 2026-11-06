import DesignTokensKit
import LocalizationKit
import UIComponentsKit
//
//  ChannelListView.swift
//  myTV
//
//  Created by Anurag Chourasia on 23/01/26.
//


import SwiftUI

struct ChannelListView: View {

    @StateObject private var viewModel: ChannelListViewModel
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.scenePhase) private var scenePhase
    @State private var developerPresented = false
    private let makeStreamListViewModel: () -> StreamListViewModel
    private let makeAboutViewModel: () -> AboutViewModel

    init(
        viewModel: ChannelListViewModel,
        makeStreamListViewModel: @escaping () -> StreamListViewModel = {
            AppDI.shared.makeStreamListViewModel()
        },
        makeAboutViewModel: @escaping () -> AboutViewModel = {
            AppDI.shared.makeAboutViewModel()
        }
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.makeStreamListViewModel = makeStreamListViewModel
        self.makeAboutViewModel = makeAboutViewModel
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: \.zero) {
                if viewModel.showOfflineBanner {
                    OfflineBanner(viewModel: viewModel.offlineBannerViewModel)
                }

                ChannelStickyBar(
                    scope: Binding(
                        get: { viewModel.channelScope },
                        set: { viewModel.setScope($0) }
                    )
                )

                content
                    .task { await viewModel.load() }
                    .onAppear {
                        viewModel.refreshAccessibilityLayoutState(
                            isAccessibilitySize: dynamicTypeSize.isAccessibilitySize
                        )
                    }
                    .onChange(of: dynamicTypeSize) { _ in
                        viewModel.refreshAccessibilityLayoutState(
                            isAccessibilitySize: dynamicTypeSize.isAccessibilitySize
                        )
                    }
            }
            .background(\.background)
            .searchable(text: $viewModel.searchText)
            .navigationTitle(viewModel.navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { menuBar }
            .tint(\.action)
            .sheet(isPresented: $developerPresented) {
                NavigationStack {
                    AboutView(viewModel: makeAboutViewModel())
                        .toolbar {
                            ToolbarItem(placement: .navigationBarLeading) {
                                Button { developerPresented = false } label: { Image(\.close) }
                                    .accessibilityLabel(\.developerCloseProfile)
                            }
                        }
                }
            }
            .alert(
                viewModel.toolbarAlertTitle,
                isPresented: $viewModel.showAlertDialog
            ) {
                Button(viewModel.toolbarAlertConfirm, role: .destructive) {
                    viewModel.confirmAction()
                }
                Button(viewModel.cancelButtonTitle, role: .cancel) {
                    viewModel.cancelAction()
                }
            }
            .alert(
                viewModel.gridAlertTitle,
                isPresented: Binding(
                    get: { viewModel.gridAlert != nil },
                    set: { if !$0 { viewModel.clearGridAlert() } }
                )
            ) {
                Button(viewModel.gridAlertOk, role: .cancel) {}
            } message: {
                Text(viewModel.gridAlertMessage)
            }
        }
        .onChange(of: scenePhase) { phase in
            guard phase == .active else { return }
            Task { @MainActor in
                await Task.yield()
                viewModel.refreshAccessibilityLayoutState(
                    isAccessibilitySize: dynamicTypeSize.isAccessibilitySize
                )
            }
        }
    }
}

// MARK: - Content
private extension ChannelListView {

    @ViewBuilder
    var content: some View {
        switch viewModel.state {
        case .loading:
            SkeletonListView()

        case .error(let message):
            ErrorView(viewModel: viewModel.errorViewModel, message: message) {
                Task { await viewModel.load() }
            }

        case .empty:
            EmptyStateMessageView(symbol: \.tvSlash, title: viewModel.channelEmptyTitle, message: viewModel.channelEmptyMessage)
                .padding(.all, \.sixteen)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .accessibilityElement(children: .combine)

        case .loaded:
            if viewModel.isFilteredEmpty {
                EmptyStateMessageView(symbol: \.magnifyingglass, title: viewModel.noResultsTitle, message: viewModel.noResultsMessage)
                .padding(.all, \.sixteen)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .accessibilityElement(children: .combine)
            } else {
                channelContent
            }
        }
    }
}

// MARK: - List / Grid
private extension ChannelListView {

    @ViewBuilder
    var channelContent: some View {
        if viewModel.shouldShowGrid(isAccessibilitySize: dynamicTypeSize.isAccessibilitySize) {
            channelGrid
        } else {
            channelList
        }
    }

    var channelList: some View {
        List {
            ForEach(viewModel.groupedResult, id: \.0) { section, channels in
                Section(viewModel.sectionTitle(for: section)) {
                    ForEach(channels) { channel in
                        NavigationLink {
                            StreamListView(
                                viewModel: makeStreamListViewModel(),
                                channelId: channel.id,
                                channelName: channel.name
                            )
                        } label: {
                            ChannelRowView(
                                channel: channel,
                                isFavorite: viewModel.favoriteChannelIDs.contains(channel.id),
                                onFavoriteToggle: {
                                    viewModel.toggleFavorite(channel.id)
                                }
                            )
                        }
                        .accessibilityHint(Text(String(\MyTVStrings.a11yChannelOpenHint)))
                    }
                }
            }
        }
    }

    var channelGrid: some View {
        ScrollView {
            LazyVStack(alignment: .leading) {
                ForEach(viewModel.groupedResult, id: \.0) { section, channels in
                    ChannelSectionHeader(title: viewModel.sectionTitle(for: section))
                    LazyVGrid(columns: [.init(.adaptive(minimum: gridMinWidth), spacing: LayoutPreset.compactMedia.itemSpacing)]) {
                        ForEach(channels) { channel in
                            NavigationLink {
                                StreamListView(
                                    viewModel: makeStreamListViewModel(),
                                    channelId: channel.id,
                                    channelName: channel.name
                                )
                            } label: {
                                ChannelGridView(
                                    channel: channel,
                                    isFavorite: viewModel.favoriteChannelIDs.contains(channel.id),
                                    onFavoriteToggle: {
                                        viewModel.toggleFavorite(channel.id)
                                    }
                                )
                            }
                            .accessibilityHint(Text(String(\MyTVStrings.a11yChannelOpenHint)))
                        }
                    }
                }
            }
            .padding(.all, LayoutPreset.compactMedia.screenInset)
        }
    }
}

private extension ChannelListView {
    var gridMinWidth: CGFloat { dynamicTypeSize.isAccessibilitySize ? DesignMetricTheme.default.p160 : DesignMetricTheme.default.p110 }
}

// MARK: - Toolbar
private extension ChannelListView {

    var menuBar: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Menu {

                // MARK: - Sort & Filter
                Section(viewModel.sortAndFilterSectionTitle) {

                    // MARK: Group By
                    Menu {
                        ForEach(ChannelListViewModel.Grouping.allCases) { grouping in
                            Button {
                                viewModel.setGrouping(grouping)
                            } label: {
                                menuLabel(
                                    title: grouping.title,
                                    isSelected: viewModel.grouping == grouping
                                )
                            }
                        }
                    } label: {
                        Label(
                            viewModel.groupByMenuTitle,
                            \.squareGrid2x2
                        )
                    }

                    // MARK: Sorting
                    Menu {

                        Section(viewModel.sectionSortingTitle) {
                            ForEach(ChannelListViewModel.SortOrder.allCases) { order in
                                Button {
                                    viewModel.setSectionSort(order)
                                } label: {
                                    menuLabel(
                                        title: order.title,
                                        isSelected: viewModel.sectionSort == order
                                    )
                                }
                            }
                        }

                        Divider()

                        Section(viewModel.channelSortingTitle) {
                            ForEach(ChannelListViewModel.SortOrder.allCases) { order in
                                Button {
                                    viewModel.setChannelSort(order)
                                } label: {
                                    menuLabel(
                                        title: order.title,
                                        isSelected: viewModel.channelSort == order
                                    )
                                }
                            }
                        }

                    } label: {
                        Label(
                            viewModel.sortingMenuTitle,
                            \.arrowUpArrowDown
                        )
                    }

                    // MARK: Filtering
                    Menu {
                        Button { viewModel.hideUnavailableStreams.toggle() } label: {
                            menuLabel(
                                title: String(\MyTVStrings.channelFilterHideUnavailable),
                                isSelected: viewModel.hideUnavailableStreams
                            )
                        }
                        .accessibilityIdentifier(.hideUnavailableStreams)
                        Divider()

                        NavigationLink {
                            MultiSelectView(
                                title: viewModel.countriesFilterTitle,
                                options: viewModel.allCountries,
                                selection: $viewModel.selectedCountries,
                                labelForOption: viewModel.countryDisplayName,
                                sortKeyForOption: viewModel.countrySortKey,
                                haptics: viewModel.haptics
                            )
                        } label: {
                            menuLabel(
                                title: viewModel.countriesFilterTitle,
                                symbol: \.globe,
                                isSelected: viewModel.hasSelectedCountryFilters
                            )
                        }

                        NavigationLink {
                            MultiSelectView(
                                title: viewModel.categoriesFilterTitle,
                                options: viewModel.allCategories,
                                selection: $viewModel.selectedCategories,
                                labelForOption: viewModel.categoryDisplayName,
                                sortKeyForOption: viewModel.categorySortKey,
                                haptics: viewModel.haptics
                            )
                        } label: {
                            menuLabel(
                                title: viewModel.categoriesFilterTitle,
                                symbol: \.tag,
                                isSelected: viewModel.hasSelectedCategoryFilters
                            )
                        }

                    } label: {
                        Label(
                            viewModel.filterMenuTitle,
                            \.line3HorizontalDecreaseCircle
                        )
                    }
                }

                Divider()

                // MARK: - Actions
                Section(viewModel.actionsSectionTitle) {

                    Button(
                        viewModel.clearCacheActionTitle,
                        role: .destructive
                    ) {
                        viewModel.requestAction(.clearCache)
                    }

                    Button(
                        viewModel.clearFiltersActionTitle,
                        role: .destructive
                    ) {
                        viewModel.requestAction(.clearFilters)
                    }

                    Button(
                        viewModel.removeFavoritesActionTitle,
                        role: .destructive
                    ) {
                        viewModel.requestAction(.removeFavorites)
                    }
                }

                Divider()

                // MARK: - Layout
                Section(viewModel.layoutSectionTitle) {
                    LayoutSwitchMenu(
                        selectedLayout: viewModel.layout,
                        onSelectLayout: viewModel.setLayout,
                        onGridUnavailable: viewModel.handleGridUnavailable,
                        isAccessibilitySize: dynamicTypeSize.isAccessibilitySize,
                        menuTitle: viewModel.layoutMenuTitle,
                        titleForLayout: viewModel.title(for:)
                    )
                }

                // MARK: - Appearance
                Section(viewModel.appearanceSectionTitle) {
                    AppearanceMenu(title: String(\MyTVStrings.appearanceMenuTitle), systemTitle: String(\MyTVStrings.appearanceSystem), lightTitle: String(\MyTVStrings.appearanceLight), darkTitle: String(\MyTVStrings.appearanceDark), onSelection: { viewModel.selectionHaptic() })
                }

                Divider()

                // MARK: - About
                Section {
                    Button { developerPresented = true } label: {
                        Label(
                            viewModel.aboutSectionTitle,
                            \.infoCircle
                        )
                    }
                }

            } label: {
                Image(\.line3Horizontal)
                    .accessibilityLabel(Text(String(\MyTVStrings.a11yMenuOptions)))
                    .accessibilityHint(Text(String(\MyTVStrings.a11yMenuOptionsHint)))
            }
        }
       
    }

    // MARK: - Menu Label Helper
    @ViewBuilder
    func menuLabel(title: String, isSelected: Bool) -> some View {
        if isSelected {
            Label(title, \.checkmark)
        } else {
            Text(title)
        }
    }

    @ViewBuilder
    func menuLabel(
        title: String,
        symbol: KeyPath<SymbolTheme, AppSymbol>,
        isSelected: Bool
    ) -> some View {
        Label(
            title,
            isSelected ? \.checkmark : symbol
        )
    }
}

#Preview {
    ChannelListView(
        viewModel: AppDI.shared.makeChannelListViewModel()
    )
}
