import DesignTokensKit
//
//  StreamListView.swift
//  myTV
//
//  Created by Anurag Chourasia on 23/01/26.
//


import SwiftUI
import LocalizationKit
import UIComponentsKit
internal import AVFoundation

struct StreamListView: View {

    @StateObject var viewModel: StreamListViewModel
    let channelId: String
    let channelName: String

    var body: some View {
        ZStack {
            content
            if viewModel.isPreparingPlayback {
                LoadingOverlayView(message: viewModel.loadingViewModel.message)
            }
        }
    }

    private var content: some View {
        VStack(spacing: \.zero) {
            if viewModel.showOfflineBanner {
                OfflineBanner(viewModel: viewModel.offlineBannerViewModel)
            }
            streamBody
        }
        .navigationTitle(channelName)
        .screenTools()
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadIfNeeded(channelId: channelId)
        }
        .sheet(
            isPresented: $viewModel.isPresentingPlayer,
            onDismiss: {
                viewModel.dismissPlayer()
            }
        ) {
            if let player = viewModel.player {
                NavigationStack {
                    StreamPlayerView(player: player)
                        .ignoresSafeArea(edges: .bottom)
                        .navigationTitle(channelName)
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarLeading) {
                                Button { viewModel.dismissPlayer() } label: { Image(\.close) }
                                    .accessibilityLabel(String(\MyTVStrings.streamPlayerClose))
                            }
                        }
                        .onAppear { player.play() }
                }
            }
        }
        .alert(
            viewModel.playbackErrorTitle,
            isPresented: Binding(
                get: { viewModel.isShowingPlaybackError },
                set: { if !$0 { viewModel.clearPlaybackError() } }
            )
        ) {
            Button(viewModel.okButtonTitle, role: .cancel) {}
        } message: {
            Text(viewModel.playbackError ?? "")
        }
    }
}

private extension StreamListView {

    @ViewBuilder
    var streamBody: some View {
        switch viewModel.state {

        case .loading:
            SkeletonListView()

        case .error(let message):
            ErrorView(viewModel: .generic, message: message) {
                Task {
                    await viewModel.reload(channelId: channelId)
                }
            }

        case .empty:
            EmptyStateMessageView(symbol: \.antennaRadiowavesLeftAndRightSlash, title: viewModel.emptyStateTitle, message: viewModel.emptyStateMessage)
                .padding(.all, \.sixteen)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .accessibilityElement(children: .combine)

        case .loaded:
            streamList
        }
    }

    var streamList: some View {
        List(viewModel.streams) { stream in
            Button {
                viewModel.playWithFallback(
                    startingFrom: stream,
                    allStreams: viewModel.streams
                )
            } label: {
                VStack(alignment: .leading, spacing: \.four) {
                    Text(stream.title)
                    if let quality = stream.quality {
                        Text(quality)
                            .font(Typography.caption)
                            .foregroundColor(\.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isPreparingPlayback)
            .accessibilityHint(Text(String(\MyTVStrings.a11yStreamPlayHint)))
            .accessibilityLabel(Text(stream.title))
            .accessibilityValue(Text(stream.quality ?? ""))
        }
        .refreshable {
            await viewModel.reload(channelId: channelId)
        }
    }
}
