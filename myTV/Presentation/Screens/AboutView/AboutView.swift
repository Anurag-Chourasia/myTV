import DesignTokensKit
import DeveloperProfileKit
import UIComponentsKit
//
//  AboutView.swift
//  myTV
//
//  Created by Anurag Chourasia on 23/01/26.
//


import SwiftUI

struct AboutView: View {

    // MARK: - ViewModel
    @StateObject private var viewModel: AboutViewModel
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.scenePhase) private var scenePhase

    // MARK: - Init
    init(viewModel: AboutViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    // MARK: - Body
    var body: some View {
        Group {
            VStack(spacing: DesignMetric.p0) {

                if viewModel.showOfflineBanner {
                    OfflineBanner(viewModel: viewModel.offlineBannerViewModel)
                }

                DeveloperProfileView(
                    app: DeveloperAppInfo(name: viewModel.appName,
                                          version: Bundle.main.appVersion,
                                          build: Bundle.main.buildNumber,
                                          disclaimer: viewModel.disclaimerText),
                    layout: viewModel.layout == .grid ? .grid : .list,
                    labels: profileLabels
                )
            }
            .navigationTitle(viewModel.navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                menuBar
            }
        }
        .background(DesignColor.grouped)
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

// MARK: - Toolbar
private extension AboutView {
    var menuBar: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Menu {
                Section(viewModel.layoutMenuSectionTitle) {
                    LayoutSwitchMenu(
                        selectedLayout: viewModel.layout,
                        onSelectLayout: viewModel.setLayout,
                        onGridUnavailable: viewModel.handleGridUnavailable,
                        isAccessibilitySize: dynamicTypeSize.isAccessibilitySize,
                        menuTitle: viewModel.layoutMenuTitle,
                        titleForLayout: viewModel.title(for:)
                    )
                }

                Section(viewModel.appearanceMenuSectionTitle) {
                    AppearanceMenu()
                }
            } label: {
                Image(systemName: "line.3.horizontal.decrease.circle")
                    .accessibilityLabel(Text(VoiceOver.A11y.Menu.options))
                    .accessibilityHint(Text(VoiceOver.A11y.Menu.Options.hint))
            }
        }
    }
}

private extension AboutView {
    var profileLabels: DeveloperProfileLabels {
        var labels = DeveloperProfileLabels()
        labels.appInformation = viewModel.appInfoTitle
        labels.version = viewModel.appVersionPrefix
        labels.disclaimer = viewModel.disclaimerTitle
        labels.social = viewModel.socialTitle
        labels.readMore = Localizable.App.readMore
        labels.showLess = Localizable.App.showLess
        labels.linkHint = VoiceOver.A11y.Openlink.hint
        labels.errorTitle = viewModel.invalidLinkAlertTitle
        labels.errorMessage = viewModel.invalidLinkAlertMessage
        labels.okay = viewModel.invalidLinkAlertOk
        return labels
    }
}
