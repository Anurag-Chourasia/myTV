import DesignTokensKit
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
            VStack(spacing: DesignMetric.p0) {
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
            .background(DesignColor.grouped)
            .searchable(text: $viewModel.searchText)
            .navigationTitle(viewModel.navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { menuBar }
            .tint(DesignColor.primary)
            .sheet(isPresented: $developerPresented) {
                NavigationStack {
                    AboutView(viewModel: makeAboutViewModel())
                        .toolbar {
                            ToolbarItem(placement: .navigationBarLeading) {
                                Button { developerPresented = false } label: { Image(systemName: "xmark") }
                                    .accessibilityLabel("Close developer profile")
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
            EmptyStateView(
                title: viewModel.channelEmptyTitle,
                message: viewModel.channelEmptyMessage,
                systemImage: "tv.slash"
            )

        case .loaded:
            if viewModel.isFilteredEmpty {
                EmptyStateView(
                    title: viewModel.noResultsTitle,
                    message: viewModel.noResultsMessage,
                    systemImage: "magnifyingglass"
                )
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
                        .accessibilityHint(Text(VoiceOver.A11y.Channel.Open.hint))
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
                    LazyVGrid(columns: [.init(.adaptive(minimum: gridMinWidth), spacing: DesignMetric.p10)]) {
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
                            .accessibilityHint(Text(VoiceOver.A11y.Channel.Open.hint))
                        }
                    }
                }
            }
            .padding(.all, Spacing.system)
        }
    }
}

private extension ChannelListView {
    var gridMinWidth: CGFloat { dynamicTypeSize.isAccessibilitySize ? DesignMetric.p160 : DesignMetric.p110 }
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
                            systemImage: "square.grid.2x2"
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
                            systemImage: "arrow.up.arrow.down"
                        )
                    }

                    // MARK: Filtering
                    Menu {
                        Button { viewModel.hideUnavailableStreams.toggle() } label: {
                            menuLabel(
                                title: "Hide channels without streams",
                                isSelected: viewModel.hideUnavailableStreams
                            )
                        }
                        .accessibilityIdentifier("hide-unavailable-streams")
                        Divider()

                        NavigationLink {
                            MultiSelectView(
                                title: viewModel.countriesFilterTitle,
                                options: viewModel.allCountries,
                                selection: $viewModel.selectedCountries,
                                labelForOption: viewModel.countryDisplayName,
                                sortKeyForOption: viewModel.countrySortKey
                            )
                        } label: {
                            menuLabel(
                                title: viewModel.countriesFilterTitle,
                                systemImage: "globe",
                                isSelected: viewModel.hasSelectedCountryFilters
                            )
                        }

                        NavigationLink {
                            MultiSelectView(
                                title: viewModel.categoriesFilterTitle,
                                options: viewModel.allCategories,
                                selection: $viewModel.selectedCategories,
                                labelForOption: viewModel.categoryDisplayName,
                                sortKeyForOption: viewModel.categorySortKey
                            )
                        } label: {
                            menuLabel(
                                title: viewModel.categoriesFilterTitle,
                                systemImage: "tag",
                                isSelected: viewModel.hasSelectedCategoryFilters
                            )
                        }

                    } label: {
                        Label(
                            viewModel.filterMenuTitle,
                            systemImage: "line.3.horizontal.decrease.circle"
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
                    AppearanceMenu()
                }

                Divider()

                // MARK: - About
                Section {
                    Button { developerPresented = true } label: {
                        Label(
                            viewModel.aboutSectionTitle,
                            systemImage: "info.circle"
                        )
                    }
                }

            } label: {
                Image(systemName: "line.3.horizontal")
                    .accessibilityLabel(Text(VoiceOver.A11y.Menu.options))
                    .accessibilityHint(Text(VoiceOver.A11y.Menu.Options.hint))
            }
        }
       
    }

    // MARK: - Menu Label Helper
    @ViewBuilder
    func menuLabel(title: String, isSelected: Bool) -> some View {
        if isSelected {
            Label(title, systemImage: "checkmark")
        } else {
            Text(title)
        }
    }

    @ViewBuilder
    func menuLabel(
        title: String,
        systemImage: String,
        isSelected: Bool
    ) -> some View {
        Label(
            title,
            systemImage: isSelected ? "checkmark" : systemImage
        )
    }
}

#Preview {
    ChannelListView(
        viewModel: AppDI.shared.makeChannelListViewModel()
    )
}
