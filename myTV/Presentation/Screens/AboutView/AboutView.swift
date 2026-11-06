import LocalizationKit
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
            VStack(spacing: \.zero) {

                if viewModel.showOfflineBanner {
                    OfflineBanner(viewModel: viewModel.offlineBannerViewModel)
                }

                DeveloperProfileView(
                    app: DeveloperAppInfo(name: viewModel.appName,
                                          version: AppRuntime.version,
                                          build: AppRuntime.build,
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
        .background(\.grouped)
        .tint(\.action)
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
                    AppearanceMenu(title: String(\MyTVStrings.appearanceMenuTitle), systemTitle: String(\MyTVStrings.appearanceSystem), lightTitle: String(\MyTVStrings.appearanceLight), darkTitle: String(\MyTVStrings.appearanceDark), onSelection: { viewModel.selectionHaptic() })
                }
            } label: {
                Image(\.line3Horizontal)
                    .accessibilityLabel(Text(String(\MyTVStrings.a11yMenuOptions)))
                    .accessibilityHint(Text(String(\MyTVStrings.a11yMenuOptionsHint)))
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
        labels.readMore = String(\MyTVStrings.readMore)
        labels.showLess = String(\MyTVStrings.showLess)
        labels.linkHint = String(\MyTVStrings.a11yOpenLinkHint)
        labels.errorTitle = viewModel.invalidLinkAlertTitle
        labels.errorMessage = viewModel.invalidLinkAlertMessage
        labels.okay = viewModel.invalidLinkAlertOk
        return labels
    }
}
