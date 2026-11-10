//
//  AppDI.swift
//  myTV
//
//  Created by Anurag Chourasia on 23/01/26.
//

import Foundation
import CommonNetworkingKit

final class AppDI {

    static let shared = AppDI()

    private lazy var haptics: HapticService =
            HapticServiceImpl()

    private lazy var reachability: ReachabilityService = ReachabilityServiceImpl()
    private lazy var imageCache: ImageCache = DefaultImageCache.shared
    private lazy var imageFetcher: any ImageDataFetching = ImageDataFetcher()

    func makeChannelRepository() -> any ChannelRepository {
        #if DEBUG
        if let scenario = AppRuntime.stubScenario { return DeveloperStubRepository(scenario: scenario) }
        #endif
        return ChannelRepositoryImpl(
            api: IPTVAPIServiceImpl(client: CommonNetworkingHTTPClient()),
            cache: ChannelDiskCache()
        )
    }

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
}
