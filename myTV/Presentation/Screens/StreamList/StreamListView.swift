//
//  StreamListView.swift
//  myTV
//
//  Created by Anurag Chourasia on 23/01/26.
//


import SwiftUI
internal import AVFoundation

struct StreamListView: View {

    @StateObject var viewModel: StreamListViewModel
    let channelId: String
    let channelName: String

    var body: some View {
        ZStack {
            content
            if viewModel.isPreparingPlayback {
                LoadingView(viewModel: viewModel.loadingViewModel)
            }
        }
    }

    private var content: some View {
        VStack(spacing: 0) {
            if viewModel.showOfflineBanner {
                OfflineBanner(viewModel: viewModel.offlineBannerViewModel)
            }
            streamBody
        }
        .navigationTitle(channelName)
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
                StreamPlayerView(player: player)
                    .ignoresSafeArea()
                    .onAppear { player.play() }
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
            EmptyStateView(
                title: viewModel.emptyStateTitle,
                message: viewModel.emptyStateMessage,
                systemImage: "antenna.radiowaves.left.and.right.slash"
            )

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
                VStack(alignment: .leading, spacing: 4) {
                    Text(stream.title)
                    if let quality = stream.quality {
                        Text(quality)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isPreparingPlayback)
            .accessibilityHint(Text(VoiceOver.A11y.Stream.Play.hint))
            .accessibilityLabel(Text(stream.title))
            .accessibilityValue(Text(stream.quality ?? ""))
        }
        .refreshable {
            await viewModel.reload(channelId: channelId)
        }
    }
}
