//
//  StreamListViewModel.swift
//  myTV
//
//  Created by Anurag Chourasia on 23/01/26.
//

import Foundation
import Combine
import AVKit

@MainActor
final class StreamListViewModel: ObservableObject {

    // MARK: - UI State
    enum UIState {
        case loading
        case loaded
        case empty
        case error(String)
    }

    // MARK: - Published
    @Published private(set) var state: UIState = .loading
    @Published private(set) var streams: [Stream] = []
    @Published var isPreparingPlayback = false
    @Published private(set) var player: AVPlayer?
    @Published var isPresentingPlayer = false
    @Published var playbackError: String?
    @Published var showOfflineBanner = false

    // MARK: - Dependencies
    private let fetchStreams: FetchStreamsForChannelUseCase
    private let reachability: ReachabilityService
    private let haptics: HapticService
    // MARK: - Internal
    private var cancellables = Set<AnyCancellable>()
    private var lastChannelId: String?

    private var playbackQueue: [Stream] = []
    private var currentStreamIndex = 0
    private var isAttemptingPlayback = false

    private var playerFailureObserver: NSObjectProtocol?
    private var statusObserver: NSKeyValueObservation?

    // MARK: - Init
    init(
        fetchStreams: DefaultFetchStreamsForChannelUseCase,
        reachability: ReachabilityService,
        haptics: HapticService
    ) {
        self.fetchStreams = fetchStreams
        self.reachability = reachability
        self.haptics = haptics
        observeReachability()
    }
}

private extension StreamListViewModel {

    func observeReachability() {
        reachability.isOnlinePublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] isOnline in
                guard let self else { return }
                showOfflineBanner = !isOnline

                guard
                    isOnline,
                    !isAttemptingPlayback,
                    case .error = state,
                    let channelId = lastChannelId
                else { return }

                Task {
                    await self.loadStreams(channelId: channelId)
                }
            }
            .store(in: &cancellables)
    }
}
extension StreamListViewModel {

    func loadStreams(channelId: String) async {
        lastChannelId = channelId
        state = .loading

        do {
            let result = try await fetchStreams.execute(channelId: channelId)
            streams = result
            state = result.isEmpty ? .empty : .loaded
        } catch {
            state = .error(error.localizedDescription)
        }
    }
}

extension StreamListViewModel {

    func playWithFallback(
        startingFrom stream: Stream,
        allStreams: [Stream]
    ) {
        haptics.impact(.light)
        guard !allStreams.isEmpty else {
            playbackError = L10n.Stream.List.Empty.title
            return
        }

        guard let startIndex = allStreams.firstIndex(of: stream) else {
            playbackError = L10n.Stream.Player.Error.title
            return
        }

        teardown()

        playbackQueue = allStreams
        currentStreamIndex = startIndex
        isAttemptingPlayback = true
        isPreparingPlayback = true
        attemptPlay()
    }

    func teardown() {
        isAttemptingPlayback = false
        isPreparingPlayback = false
        removePlayerObservers()
        player?.replaceCurrentItem(with: nil)
        player?.pause()
        player = nil
    }
}
private extension StreamListViewModel {

    func attemptPlay() {
        guard currentStreamIndex < playbackQueue.count else {
            isAttemptingPlayback = false
            playbackError = L10n.Stream.Player.Error.noWorkingStreams
            return
        }

        play(stream: playbackQueue[currentStreamIndex])
    }

    func play(stream: Stream) {
        guard let url = URL(string: stream.url) else {
            handlePlaybackFailure(message: L10n.Stream.Player.Error.invalidURL)
            return
        }

        removePlayerObservers()

        let item = AVPlayerItem(url: url)
        let player = AVPlayer(playerItem: item)
        self.player = player
        self.playbackError = nil

        statusObserver = item.observe(\.status, options: [.initial, .new]) { [weak self] item, _ in
            guard let self else { return }

            Task { @MainActor in
                switch item.status {

                case .readyToPlay:
                    self.isPreparingPlayback = false
                    self.isPresentingPlayer = true
                    self.haptics.notification(.success)

                case .failed:
                    self.handlePlaybackFailure(
                        message: item.error?.localizedDescription
                            ?? L10n.Stream.Player.Error.cannotPlay
                    )

                case .unknown:
                    break

                @unknown default:
                    break
                }
            }
        }

        playerFailureObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemFailedToPlayToEndTime,
            object: item,
            queue: nil
        ) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                self.handlePlaybackFailure(message: L10n.Stream.Player.Error.cannotPlay)
            }
        }
    }

    func handlePlaybackFailure(message: String) {
        removePlayerObservers()
        currentStreamIndex += 1

        if currentStreamIndex < playbackQueue.count {
            attemptPlay()
        } else {
            isPreparingPlayback = false
            teardown()
            playbackError = message
            haptics.notification(.error)
        }
    }

    func removePlayerObservers() {
        if let observer = playerFailureObserver {
            NotificationCenter.default.removeObserver(observer)
            playerFailureObserver = nil
        }
        statusObserver = nil
    }
}
