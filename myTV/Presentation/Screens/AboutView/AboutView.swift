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
            VStack(spacing: 0) {

                if viewModel.showOfflineBanner {
                    OfflineBanner(viewModel: viewModel.offlineBannerViewModel)
                }

                ScrollView {
                    VStack(spacing: 0) {
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
        .background(Color(UIColor.systemGroupedBackground))
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
        VStack(spacing: 16) {
            Image(viewModel.developerImageName)
                .resizable()
                .scaledToFit()
                .frame(width: 100)
                .clipShape(Circle())
                .overlay(
                    Circle().stroke(.secondary, lineWidth: 1)
                )
                .accessibilityHidden(true)

            Text(viewModel.developerName)
                .font(.title2)
                .fontWeight(.bold)

            Text(viewModel.developerRole)
                .foregroundStyle(.secondary)

            TypingEffectView()
        }
        .padding()
    }

    var appInfoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(viewModel.appInfoTitle)
                .font(.headline)

            Text(viewModel.appName)

            Text(
                "\(viewModel.appVersionPrefix) \(Bundle.main.appVersion) (\(Bundle.main.buildNumber))"
            )
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
    }

    var disclaimerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(viewModel.disclaimerTitle)
                .font(.headline)

            Text(LocalizedStringKey(viewModel.disclaimerText))
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.leading)
                .tint(.blue)
                .fixedSize(horizontal: false, vertical: true)
                .textSelection(.disabled)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
    }

    var divider: some View {
        Rectangle()
            .frame(height: 1)
            .foregroundColor(Color(uiColor: .separator))
    }
}

// MARK: - Social
private extension AboutView {
    @ViewBuilder
    var socialLinksSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(viewModel.socialTitle)
                .font(.headline)
            
            if viewModel.shouldUseGridLayout(isAccessibilitySize: dynamicTypeSize.isAccessibilitySize) {
                LazyVGrid(columns: [.init(.adaptive(minimum: 110))]) {
                    ForEach(viewModel.socialLinks) { link in
                        gridLinkButton(link)
                    }
                }
            } else {
                VStack(spacing: 0) {
                    ForEach(viewModel.socialLinks) { link in
                        listLinkButton(link)
                        
                        if link.id != viewModel.socialLinks.last?.id {
                            Divider()
                                .padding(.leading, 60)
                                .padding(.trailing, 12)
                        }
                    }
                }
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .cornerRadius(12)
            }
        }
        .padding()
    }

    func listLinkButton(_ link: SocialLink) -> some View {
        Button {
            openLink(link)
        } label: {
            HStack(spacing: 12) {
                Image(link.icon)
                    .resizable()
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .frame(width: 36, height: 36)
                    .accessibilityHidden(true)

                Text(link.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .padding(.horizontal, 8)

                Spacer()
            }
            .padding()
            .accessibilityElement(children: .combine)
        }
        .accessibilityLabel(Text(link.title))
        .accessibilityHint(Text(VoiceOver.A11y.Openlink.hint))
    }
    
    func gridLinkButton(_ link: SocialLink) -> some View {
        Button {
            openLink(link)
        } label: {
            VStack(spacing: 12) {
                Image(link.icon)
                    .resizable()
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .frame(width: socialIconSize, height: socialIconSize)
                    .accessibilityHidden(true)

                Text(link.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .padding(.horizontal, 8)
            }
            .frame(width: socialContentSize, height: socialContentSize)
            .accessibilityElement(children: .combine)
        }
        .frame(width: socialCardSize, height: socialCardSize)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
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
    var socialIconSize: CGFloat { 64 }
    var socialContentSize: CGFloat { 110 }
    var socialCardSize: CGFloat { 120 }
}
