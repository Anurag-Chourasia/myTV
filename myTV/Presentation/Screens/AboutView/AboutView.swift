import DesignTokensKit
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
    @Environment(\.openURL) private var openURL

    // MARK: - Init
    init(viewModel: AboutViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    // MARK: - Body
    var body: some View {
        NavigationStack {
            VStack(spacing: DesignMetric.p0) {

                if viewModel.showOfflineBanner {
                    OfflineBanner(viewModel: viewModel.offlineBannerViewModel)
                }

                ScrollView {
                    VStack(spacing: DesignMetric.p0) {
                        developerSection
                        divider
                        appInfoSection
                        divider
                        disclaimerSection
                        divider
                        socialLinksSection
                    }
                }
            }
            .navigationTitle(viewModel.navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                menuBar
            }
        }
        .background(DesignColor.grouped)
        .alert(
            viewModel.invalidLinkAlertTitle,
            isPresented: $viewModel.showAlert
        ) {
            Button(viewModel.invalidLinkAlertOk, role: .cancel) {}
        } message: {
            Text(viewModel.invalidLinkAlertMessage)
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

// MARK: - Sections
private extension AboutView {

    var developerSection: some View {
        VStack(spacing: DesignMetric.p16) {
            Image(viewModel.developerImageName)
                .resizable()
                .scaledToFit()
                .frame(width: DesignMetric.p100)
                .clipShape(Circle())
                .overlay(
                    Circle().stroke(DesignColor.secondary, lineWidth: DesignMetric.p1)
                )
                .accessibilityHidden(true)

            Text(viewModel.developerName)
                .font(Typography.title2)
                .fontWeight(.bold)

            Text(viewModel.developerRole)
                .foregroundStyle(DesignColor.secondary)

            TypingEffectView()
        }
        .padding(.all, Spacing.system)
    }

    var appInfoSection: some View {
        VStack(alignment: .leading, spacing: DesignMetric.p8) {
            Text(viewModel.appInfoTitle)
                .font(Typography.headline)

            Text(viewModel.appName)

            Text(
                "\(viewModel.appVersionPrefix) \(Bundle.main.appVersion) (\(Bundle.main.buildNumber))"
            )
            .foregroundStyle(DesignColor.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.all, Spacing.system)
    }

    var disclaimerSection: some View {
        VStack(alignment: .leading, spacing: DesignMetric.p10) {
            Text(viewModel.disclaimerTitle)
                .font(Typography.headline)

            Text(LocalizedStringKey(viewModel.disclaimerText))
                .font(Typography.footnote)
                .foregroundStyle(DesignColor.secondary)
                .multilineTextAlignment(.leading)
                .tint(DesignColor.blue)
                .fixedSize(horizontal: false, vertical: true)
                .textSelection(.disabled)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.all, Spacing.system)
    }

    var divider: some View {
        Rectangle()
            .frame(height: DesignMetric.p1)
            .foregroundColor(DesignColor.separator)
    }
}

// MARK: - Social
private extension AboutView {
    @ViewBuilder
    var socialLinksSection: some View {
        VStack(alignment: .leading, spacing: DesignMetric.p16) {
            Text(viewModel.socialTitle)
                .font(Typography.headline)
            
            if viewModel.shouldUseGridLayout(isAccessibilitySize: dynamicTypeSize.isAccessibilitySize) {
                LazyVGrid(columns: [.init(.adaptive(minimum: DesignMetric.p110))]) {
                    ForEach(viewModel.socialLinks) { link in
                        gridLinkButton(link)
                    }
                }
            } else {
                VStack(spacing: DesignMetric.p0) {
                    ForEach(viewModel.socialLinks) { link in
                        listLinkButton(link)
                        
                        if link.id != viewModel.socialLinks.last?.id {
                            Divider()
                                .padding(.leading, DesignMetric.p60)
                                .padding(.trailing, DesignMetric.p12)
                        }
                    }
                }
                .background(DesignColor.groupedSecondary)
                .cornerRadius(DesignMetric.p12)
            }
        }
        .padding(.all, Spacing.system)
    }

    func listLinkButton(_ link: SocialLink) -> some View {
        Button {
            openLink(link)
        } label: {
            HStack(spacing: DesignMetric.p12) {
                Image(link.icon)
                    .resizable()
                    .background(DesignColor.groupedSecondary)
                    .frame(width: DesignMetric.p36, height: DesignMetric.p36)
                    .accessibilityHidden(true)

                Text(link.title)
                    .font(Typography.headline)
                    .foregroundColor(DesignColor.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(TextLineLimit.p2)
                    .padding(.horizontal, DesignMetric.p8)

                Spacer()
            }
            .padding(.all, Spacing.system)
            .accessibilityElement(children: .combine)
        }
        .accessibilityLabel(Text(link.title))
        .accessibilityHint(Text(VoiceOver.A11y.Openlink.hint))
    }
    
    func gridLinkButton(_ link: SocialLink) -> some View {
        Button {
            openLink(link)
        } label: {
            VStack(spacing: DesignMetric.p12) {
                Image(link.icon)
                    .resizable()
                    .background(DesignColor.groupedSecondary)
                    .frame(width: socialIconSize, height: socialIconSize)
                    .accessibilityHidden(true)

                Text(link.title)
                    .font(Typography.headline)
                    .foregroundColor(DesignColor.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(TextLineLimit.p2)
                    .padding(.horizontal, DesignMetric.p8)
            }
            .frame(width: socialContentSize, height: socialContentSize)
            .accessibilityElement(children: .combine)
        }
        .frame(width: socialCardSize, height: socialCardSize)
        .background(DesignColor.groupedSecondary)
        .clipShape(RoundedRectangle(cornerRadius: DesignMetric.p20, style: .continuous))
        .accessibilityLabel(Text(link.title))
        .accessibilityHint(Text(VoiceOver.A11y.Openlink.hint))
    }

    private func openLink(_ link: SocialLink) {
        openURL(link.url) { accepted in
            if !accepted {
                viewModel.handleInvalidLink()
            }
        }
    }
}

private extension AboutView {
    var socialIconSize: CGFloat { DesignMetric.p64 }
    var socialContentSize: CGFloat { DesignMetric.p110 }
    var socialCardSize: CGFloat { DesignMetric.p120 }
}
