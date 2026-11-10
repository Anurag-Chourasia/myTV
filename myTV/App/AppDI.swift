//
//  AppDI.swift
//  myTV
//
//  Created by Anurag Chourasia on 23/01/26.
//

import Foundation
import CommonNetworkingKit
import FoundationKit

final class AppDI {

    static let shared = AppDI()

    private lazy var haptics: HapticService =
            HapticServiceImpl()

    private lazy var reachability: ReachabilityService = ReachabilityServiceImpl()
    private lazy var imageCache: ImageCache = DefaultImageCache.shared
    private lazy var imageFetcher: any ImageDataFetching = ImageDataFetcher()
    private lazy var clock: any AppClock = SystemClock()
    private lazy var mainQueue: any MainQueueDispatching = MainQueueDispatcher()
    private lazy var logger: any AppLogger = UnifiedLogger(subsystem: "com.mytv.app", category: "lifecycle")
    private lazy var byteFormatter: any ByteCountFormatting = ByteCountFormatterFactory.make()

    func makeChannelRepository() -> any ChannelRepository {
        #if DEBUG
        if let scenario = AppRuntime.stubScenario { return DeveloperStubRepository(scenario: scenario) }
        #endif
        return ChannelRepositoryImpl(
            api: IPTVAPIServiceImpl(client: CommonNetworkingHTTPClient()),
            cache: ChannelDiskCache(byteFormatter: byteFormatter, logger: logger, clock: clock)
        )
    }

    @MainActor
    func makeChannelListViewModel(
        favorites: (any FavoriteChannelStoring)? = nil,
        ownerID: UUID? = nil
    ) -> ChannelListViewModel {
        let repository = makeChannelRepository()
        let fetchChannels = DefaultFetchChannelsUseCase(repository: repository)
        let filterChannels = DefaultFilterChannelsUseCase()
        let manageCache = DefaultManageChannelCacheUseCase(repository: repository)
        let resolvedFavorites = favorites ?? FavoriteChannelStore(ownerID: ownerID)
        return ChannelListViewModel(
            fetchChannels: fetchChannels,
            filterChannels: filterChannels,
            manageCache: manageCache,
            reachability: reachability,
            haptics: haptics,
            favorites: resolvedFavorites,
            imageCache: imageCache
        )
    }

    @MainActor
    func makeStreamListViewModel() -> StreamListViewModel {
        let fetchStreams = DefaultFetchStreamsForChannelUseCase(
            repository: makeChannelRepository()
        )
        return StreamListViewModel(
            fetchStreams: fetchStreams,
            reachability: reachability,
            haptics: haptics
        )
    }

    func makeManageChannelCacheUseCase() -> any ManageChannelCacheUseCase {
        DefaultManageChannelCacheUseCase(repository: makeChannelRepository())
    }

    func makeFilterChannelsUseCase() -> any FilterChannelsUseCase {
        DefaultFilterChannelsUseCase()
    }

    @MainActor
    func makeAboutViewModel() -> AboutViewModel {
        return AboutViewModel(
            reachability: reachability,
            haptics: haptics
        )
    }
    
    func getHaptics() -> HapticService {
        haptics
    }

    func getImageCache() -> ImageCache {
        imageCache
    }

    func getImageDataFetcher() -> any ImageDataFetching {
        imageFetcher
    }

    func getClock() -> any AppClock {
        clock
    }

    func getMainQueue() -> any MainQueueDispatching {
        mainQueue
    }

    func getLogger() -> any AppLogger {
        logger
    }

    func getByteFormatter() -> any ByteCountFormatting {
        byteFormatter
    }
}
