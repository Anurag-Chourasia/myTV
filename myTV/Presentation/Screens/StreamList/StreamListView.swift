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
                LoadingView()
            }
        }
    }

    private var content: some View {
        VStack(spacing: 0) {
            if viewModel.showOfflineBanner {
                OfflineBanner()
            }
            streamBody
        }
        .navigationTitle(channelName)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if case .loading = viewModel.state {
                await viewModel.loadStreams(channelId: channelId)
            }
        }
        .sheet(
            isPresented: $viewModel.isPresentingPlayer,
            onDismiss: {
                viewModel.teardown()
            }
        ) {
            if let player = viewModel.player {
                StreamPlayerView(player: player)
                    .ignoresSafeArea()
                    .onAppear { player.play() }
            }
        }
        .alert(
            L10n.Stream.Player.Error.title,
            isPresented: Binding(
                get: { viewModel.playbackError != nil },
                set: { if !$0 { viewModel.playbackError = nil } }
            )
        ) {
            Button(L10n.App.ok, role: .cancel) {}
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
            ErrorView(message: message) {
                Task {
                    await viewModel.loadStreams(channelId: channelId)
                }
            }

        case .empty:
            EmptyStateView(
                title: L10n.Stream.List.Empty.title,
                message: L10n.Stream.List.Empty.message,
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
        }
        .refreshable {
            await viewModel.loadStreams(channelId: channelId)
        }
    }
}
