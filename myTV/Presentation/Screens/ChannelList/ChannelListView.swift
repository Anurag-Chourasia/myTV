//
//  ChannelListView.swift
//  myTV
//
//  Created by Anurag Chourasia on 23/01/26.
//


import SwiftUI

struct ChannelListView: View {

    @StateObject private var viewModel: ChannelListViewModel

    init(viewModel: ChannelListViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if viewModel.showOfflineBanner {
                    OfflineBanner()
                }

                ChannelStickyBar(
                    scope: Binding(
                        get: { viewModel.channelScope },
                        set: { viewModel.setScope($0) }
                    )
                )

                content
            }
            .background(Color(UIColor.systemGroupedBackground))
            .searchable(text: $viewModel.searchText)
            .navigationTitle(L10n.App.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { menuBar }
            .alert(
                viewModel.pendingAction == nil ? "" : alertTitle,
                isPresented: $viewModel.showAlertDialog
            ) {
                Button(alertConfirm, role: .destructive) {
                    viewModel.confirmAction()
                }
                Button(L10n.App.cancel, role: .cancel) {
                    viewModel.cancelAction()
                }
            }
        }
        .task { await viewModel.load() }
    }

    private var alertTitle: String {
        switch viewModel.pendingAction {
        case .clearCache: return L10n.Channel.Alert.Clear.Cache.title
        case .clearFilters: return L10n.Channel.Alert.Clear.Filters.title
        case .removeFavorites: return L10n.Channel.Alert.Remove.Favorites.title
        case .none: return ""
        }
    }

    private var alertConfirm: String {
        switch viewModel.pendingAction {
        case .clearCache: return L10n.Channel.Alert.Clear.Cache.confirm
        case .clearFilters: return L10n.Channel.Alert.Clear.Filters.confirm
        case .removeFavorites: return L10n.Channel.Alert.Remove.Favorites.confirm
        case .none: return ""
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
            ErrorView(message: message) {
                Task { await viewModel.load() }
            }

        case .empty:
            EmptyStateView(
                title: L10n.Channel.Empty.title,
                message: L10n.Channel.Empty.message,
                systemImage: "tv.slash"
            )

        case .loaded:
            if viewModel.isFilteredEmpty {
                EmptyStateView(
                    title: L10n.Channel.No.Results.title,
                    message: L10n.Channel.No.Results.message,
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
        switch viewModel.layout {
        case .list:
            channelList
        case .grid:
            channelGrid
        }
    }

    var channelList: some View {
        List {
            ForEach(viewModel.groupedResult, id: \.0) { section, channels in
                Section(section) {
                    ForEach(channels) { channel in
                        NavigationLink {
                            StreamListView(
                                viewModel: AppDI.shared.makeStreamListViewModel(),
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
                    }
                }
            }
        }
    }

    var channelGrid: some View {
        ScrollView {
            LazyVStack(alignment: .leading) {
                ForEach(viewModel.groupedResult, id: \.0) { section, channels in
                    ChannelSectionHeader(title: section)
                    LazyVGrid(columns: [.init(.adaptive(minimum: 110), spacing: 10)]) {
                        ForEach(channels) { channel in
                            NavigationLink {
                                StreamListView(
                                    viewModel: AppDI.shared.makeStreamListViewModel(),
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
                        }
                    }
                }
            }
            .padding()
        }
    }
}

// MARK: - Toolbar
private extension ChannelListView {

    var menuBar: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Menu {

                // MARK: - Sort & Filter
                Section(L10n.Channel.Menu.Section.Sortandfilter.title) {

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
                            L10n.Channel.Menu.Section.GroupBy.title,
                            systemImage: "square.grid.2x2"
                        )
                    }

                    // MARK: Sorting
                    Menu {

                        Section(L10n.Channel.Menu.Section.Section.title) {
                            ForEach(ChannelListViewModel.SortOrder.allCases) { order in
                                Button {
                                    viewModel.sectionSort = order
                                } label: {
                                    menuLabel(
                                        title: order.title,
                                        isSelected: viewModel.sectionSort == order
                                    )
                                }
                            }
                        }

                        Divider()

                        Section(L10n.Channel.Menu.Section.Channel.title) {
                            ForEach(ChannelListViewModel.SortOrder.allCases) { order in
                                Button {
                                    viewModel.channelSort = order
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
                            L10n.Channel.Menu.Section.Sorting.title,
                            systemImage: "arrow.up.arrow.down"
                        )
                    }

                    // MARK: Filtering
                    Menu {

                        NavigationLink {
                            MultiSelectView(
                                title: L10n.Channel.Filter.countries,
                                options: viewModel.allCountries,
                                selection: $viewModel.selectedCountries
                            )
                        } label: {
                            Label(
                                L10n.Channel.Filter.countries,
                                systemImage: "globe"
                            )
                        }

                        NavigationLink {
                            MultiSelectView(
                                title: L10n.Channel.Filter.categories,
                                options: viewModel.allCategories,
                                selection: $viewModel.selectedCategories
                            )
                        } label: {
                            Label(
                                L10n.Channel.Filter.categories,
                                systemImage: "tag"
                            )
                        }

                    } label: {
                        Label(
                            L10n.Channel.Menu.Section.Filter.title,
                            systemImage: "line.3.horizontal.decrease.circle"
                        )
                    }
                }

                Divider()

                // MARK: - Actions
                Section(L10n.Channel.Menu.Section.actions) {

                    Button(
                        L10n.Channel.Menu.Action.clearCache,
                        role: .destructive
                    ) {
                        viewModel.requestAction(.clearCache)
                    }

                    Button(
                        L10n.Channel.Menu.Action.clearFilters,
                        role: .destructive
                    ) {
                        viewModel.requestAction(.clearFilters)
                    }

                    Button(
                        L10n.Channel.Menu.Action.removeFavorites,
                        role: .destructive
                    ) {
                        viewModel.requestAction(.removeFavorites)
                    }
                }

                Divider()

                // MARK: - Layout
                Section(L10n.Channel.Menu.Section.layout) {
                    LayoutSwitchMenu()
                }

                // MARK: - Appearance
                Section(L10n.Channel.Menu.Section.appearance) {
                    AppearanceMenu()
                }

                Divider()

                // MARK: - About
                Section {
                    NavigationLink {
                        AboutView(
                            viewModel: AppDI.shared.makeAboutViewModel()
                        )
                    } label: {
                        Label(
                            L10n.Channel.Menu.Section.about,
                            systemImage: "info.circle"
                        )
                    }
                }

            } label: {
                Image(systemName: "line.3.horizontal.decrease.circle")
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
}

#Preview {
    ChannelListView(
        viewModel: AppDI.shared.makeChannelListViewModel()
    )
}

