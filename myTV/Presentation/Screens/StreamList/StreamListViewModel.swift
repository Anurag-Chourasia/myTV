import LocalizationKit
//
//  StreamListViewModel.swift
//  myTV
//
//  Created by Anurag Chourasia on 23/01/26.
//

import Foundation
import Combine
import AVKit
import UIKit

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
    private let notificationCenter: NotificationCenter

    // MARK: - Internal
    private var cancellables = Set<AnyCancellable>()
    private var lastChannelId: String?
    private var loadStreamsTask: Task<Void, Never>?

    private var playbackQueue: [Stream] = []
    private var currentStreamIndex = 0
    private var isAttemptingPlayback = false
    private var sessionID = UUID()

    private var playerFailureObserver: NSObjectProtocol?
    private var statusObserver: NSKeyValueObservation?
    private var audioInterruptionObserver: NSObjectProtocol?
    private var audioRouteChangeObserver: NSObjectProtocol?
    private var backgroundObserver: NSObjectProtocol?

    // MARK: - Init
    init(
        fetchStreams: DefaultFetchStreamsForChannelUseCase,
        reachability: ReachabilityService,
        haptics: HapticService,
        notificationCenter: NotificationCenter = .default
    ) {
        self.fetchStreams = fetchStreams
        self.reachability = reachability
        self.haptics = haptics
        self.notificationCenter = notificationCenter
        observeReachability()
        observeSystemAudioAndLifecycle()
    }

    deinit {
        if let observer = audioInterruptionObserver {
            notificationCenter.removeObserver(observer)
        }
        if let observer = audioRouteChangeObserver {
            notificationCenter.removeObserver(observer)
        }
        if let observer = backgroundObserver {
            notificationCenter.removeObserver(observer)
        }
        if let observer = playerFailureObserver {
            notificationCenter.removeObserver(observer)
        }
        loadStreamsTask?.cancel()
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

    func observeSystemAudioAndLifecycle() {
        #if canImport(UIKit) && !os(macOS)
        // 1. Audio session interruptions (phone calls, FaceTime, Siri)
        audioInterruptionObserver = notificationCenter.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            Task { @MainActor [weak self] in
                self?.handleAudioInterruption(notification)
            }
        }

        // 2. Audio route changes (unplugging headphones, disconnecting Bluetooth)
        audioRouteChangeObserver = notificationCenter.addObserver(
            forName: AVAudioSession.routeChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            Task { @MainActor [weak self] in
                self?.handleAudioRouteChange(notification)
            }
        }

        // 3. App moving to background (pause if PiP is not active to prevent zombie threads)
        backgroundObserver = notificationCenter.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.handleDidEnterBackground()
            }
        }
        #endif
    }

    #if canImport(UIKit) && !os(macOS)
    func handleAudioInterruption(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let interruptionType = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }

        switch interruptionType {
        case .began:
            player?.pause()
        case .ended:
            if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                if options.contains(.shouldResume), isPresentingPlayer {
                    player?.play()
                }
            }
        @unknown default:
            break
        }
    }

    func handleAudioRouteChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else { return }

        switch reason {
        case .oldDeviceUnavailable:
            // Standard iOS guideline: pause playback when headphones are disconnected
            player?.pause()
        default:
            break
        }
    }

    func handleDidEnterBackground() {
        // In full-screen modal player, if backgrounded, pause player
        if isPresentingPlayer {
            player?.pause()
        }
    }
    #endif
}

extension StreamListViewModel {
    var offlineBannerViewModel: OfflineBannerViewModel {
        .default
    }

    var loadingViewModel: LoadingViewModel {
        .streamPreparationDefault
    }

    var emptyStateTitle: String {
        String(\MyTVStrings.streamListEmptyTitle)
    }

    var emptyStateMessage: String {
        String(\MyTVStrings.streamListEmptyMessage)
    }

    var playbackErrorTitle: String {
        String(\MyTVStrings.playbackErrorTitle)
    }

    var okButtonTitle: String {
        LocalizationController.shared.string("app.ok")
    }

    func loadStreams(channelId: String) async {
        loadStreamsTask?.cancel()
        lastChannelId = channelId
        state = .loading

        let task = Task { [fetchStreams] () throws -> [Stream] in
            try Task.checkCancellation()
            let result = try await fetchStreams.execute(channelId: channelId)
            try Task.checkCancellation()
            return result
        }
        loadStreamsTask = Task { [weak self] in
            do {
                let result = try await task.value
                guard !Task.isCancelled, let self else { return }
                self.streams = result
                self.state = result.isEmpty ? .empty : .loaded
            } catch is CancellationError {
                // Task was explicitly cancelled due to rapid switching or new request; do not overwrite state
            } catch {
                guard !Task.isCancelled, let self else { return }
                self.streams = []
                self.state = .error(error.localizedDescription)
            }
        }
        await loadStreamsTask?.value
    }

    func loadIfNeeded(channelId: String) async {
        guard case .loading = state else { return }
        await loadStreams(channelId: channelId)
    }

    func reload(channelId: String) async {
        await loadStreams(channelId: channelId)
    }

    func dismissPlayer() {
        teardown()
    }

    func clearPlaybackError() {
        playbackError = nil
    }

    var isShowingPlaybackError: Bool {
        playbackError != nil
    }
}

extension StreamListViewModel {

    func playWithFallback(
        startingFrom stream: Stream,
        allStreams: [Stream]
    ) {
        haptics.impact(.light)
        guard !allStreams.isEmpty else {
            playbackError = String(\MyTVStrings.streamListEmptyTitle)
            return
        }

        guard let startIndex = allStreams.firstIndex(of: stream) else {
            playbackError = String(\MyTVStrings.playbackErrorTitle)
            return
        }

        teardown()

        sessionID = UUID()
        playbackQueue = allStreams
        currentStreamIndex = startIndex
        isAttemptingPlayback = true
        isPreparingPlayback = true
        attemptPlay(for: sessionID)
    }

    func teardown() {
        sessionID = UUID() // invalidate any pending callbacks
        isAttemptingPlayback = false
        isPresentingPlayer = false
        isPreparingPlayback = false
        removePlayerObservers()
        player?.replaceCurrentItem(with: nil)
        player?.pause()
        player = nil
    }
}

private extension StreamListViewModel {

    func attemptPlay(for targetSession: UUID) {
        guard isAttemptingPlayback, targetSession == sessionID else { return }

        guard currentStreamIndex < playbackQueue.count else {
            teardown()
            playbackError = String(\MyTVStrings.noWorkingStreams)
            return
        }

        play(stream: playbackQueue[currentStreamIndex], for: targetSession)
    }

    func play(stream: Stream, for targetSession: UUID) {
        guard isAttemptingPlayback, targetSession == sessionID else { return }

        guard let url = URL(string: stream.url) else {
            handlePlaybackFailure(message: String(\MyTVStrings.invalidStreamURL), for: targetSession)
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
                guard self.isAttemptingPlayback,
                      self.sessionID == targetSession,
                      self.player?.currentItem === item else { return }

                switch item.status {
                case .readyToPlay:
                    self.isPreparingPlayback = false
                    self.isPresentingPlayer = true
                    self.haptics.notification(.success)

                case .failed:
                    self.handlePlaybackFailure(
                        message: item.error?.localizedDescription
                            ?? String(\MyTVStrings.cannotPlayStream),
                        for: targetSession
                    )

                case .unknown:
                    break

                @unknown default:
                    break
                }
            }
        }

        playerFailureObserver = notificationCenter.addObserver(
            forName: .AVPlayerItemFailedToPlayToEndTime,
            object: item,
            queue: nil
        ) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                guard self.isAttemptingPlayback,
                      self.sessionID == targetSession,
                      self.player?.currentItem === item else { return }
                self.handlePlaybackFailure(message: String(\MyTVStrings.cannotPlayStream), for: targetSession)
            }
        }
    }

    func handlePlaybackFailure(message: String, for targetSession: UUID) {
        guard isAttemptingPlayback, targetSession == sessionID else { return }
        removePlayerObservers()
        currentStreamIndex += 1

        if currentStreamIndex < playbackQueue.count {
            attemptPlay(for: targetSession)
        } else {
            isPreparingPlayback = false
            teardown()
            playbackError = message
            haptics.notification(.error)
        }
    }

    func removePlayerObservers() {
        if let observer = playerFailureObserver {
            notificationCenter.removeObserver(observer)
            playerFailureObserver = nil
        }
        statusObserver = nil
    }
}
