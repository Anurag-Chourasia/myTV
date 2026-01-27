//
//  AboutView.swift
//  myTV
//
//  Created by Anurag Chourasia on 23/01/26.
//


import SwiftUI
import Combine

struct AboutView: View {

    // MARK: - ViewModel
    @StateObject private var viewModel: AboutViewModel

    // MARK: - Init
    init(viewModel: AboutViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    // MARK: - Body
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {

                if viewModel.showOfflineBanner {
                    OfflineBanner()
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
            .navigationTitle(L10n.About.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                menuBar
            }
        }
        .background(Color(UIColor.systemGroupedBackground))
        .alert(
            L10n.About.Alert.Error.title,
            isPresented: $viewModel.showAlert
        ) {
            Button(L10n.About.Alert.Error.ok, role: .cancel) {}
        } message: {
            Text(L10n.About.Alert.Error.invalidLink)
        }
    }
}

// MARK: - Toolbar
private extension AboutView {
    var menuBar: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Menu {
                Section(L10n.About.Menu.layout) {
                    LayoutSwitchMenu()
                }

                Section(L10n.About.Menu.appearance) {
                    AppearanceMenu()
                }
            } label: {
                Image(systemName: "line.3.horizontal.decrease.circle")
            }
        }
    }
}

// MARK: - Sections
private extension AboutView {

    var developerSection: some View {
        VStack(spacing: 16) {
            Image(L10n.App.Developer.firstName)
                .resizable()
                .scaledToFit()
                .frame(width: 100)
                .clipShape(Circle())
                .overlay(
                    Circle().stroke(.secondary, lineWidth: 1)
                )

            Text(L10n.About.Developer.name)
                .font(.title2)
                .fontWeight(.bold)

            Text(L10n.About.Developer.role)
                .foregroundStyle(.secondary)

            TypingEffectView()
        }
        .padding()
    }

    var appInfoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.About.App.Info.title)
                .font(.headline)

            Text(L10n.About.App.name)

            Text(
                "\(L10n.About.App.Version.prefix) \(Bundle.main.appVersion) (\(Bundle.main.buildNumber))"
            )
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
    }

    var disclaimerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(L10n.About.Disclaimer.title)
                .font(.headline)

            Text(LocalizedStringKey(L10n.About.Disclaimer.text))
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

    var socialLinks: [SocialLink] {
        [
            .init(
                title: L10n.About.Social.github,
                icon: L10n.About.Social.github,
                url: URL(string: L10n.About.Social.Github.url)!
            ),
            .init(
                title: L10n.About.Social.linkedin,
                icon: L10n.About.Social.linkedin,
                url: URL(string: L10n.About.Social.Linkedin.url)!
            ),
            .init(
                title: L10n.About.Social.email,
                icon: L10n.About.Social.gmail,
                url: URL(string: L10n.About.Social.Email.url)!
            ),
            .init(
                title: L10n.About.Social.cv,
                icon: L10n.About.Social.cv,
                url: URL(string: L10n.About.Social.Cv.url)!
            )
        ]
    }

    @ViewBuilder
    var socialLinksSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(L10n.About.Social.title)
                .font(.headline)
            
            if viewModel.layout == .grid {
                LazyVGrid(columns: [.init(.adaptive(minimum: 110))]) {
                    ForEach(socialLinks, id: \.title) { link in
                        gridLinkButton(link)
                    }
                }
            } else {
                VStack(spacing: 0) {
                    ForEach(socialLinks, id: \.title) { link in
                        listLinkButton(link)
                        
                        if link.title != socialLinks.last?.title {
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
            linkButtonAction(link)
        } label: {
            HStack(spacing: 12) {
                Image(link.icon)
                    .resizable()
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .frame(width: 36, height: 36)

                Text(link.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .padding(.horizontal, 8)

                Spacer()
            }
            .padding()
        }
    }
    
    func gridLinkButton(_ link: SocialLink) -> some View {
        Button {
            linkButtonAction(link)
        } label: {
            VStack(spacing: 12) {
                Image(link.icon)
                    .resizable()
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .frame(width: 64, height: 64)

                Text(link.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .padding(.horizontal, 8)
            }
            .frame(width: 110, height: 110)
        }
        .frame(width: 120, height: 120)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
    
    private func linkButtonAction(_ link: SocialLink) {
        if UIApplication.shared.canOpenURL(link.url) {
            UIApplication.shared.open(link.url)
        } else {
            viewModel.handleInvalidLink()
        }
    }
}

// MARK: - Models
private struct SocialLink {
    let title: String
    let icon: String
    let url: URL
}

// MARK: - Bundle Helpers
extension Bundle {
    var appVersion: String {
        infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    var buildNumber: String {
        infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
}
