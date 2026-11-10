//
//  AppDI.swift
//  myTV
//
//  Created by Anurag Chourasia on 23/01/26.
//

import Foundation

final class AppDI {

    static let shared = AppDI()

    private lazy var haptics: HapticService =
            HapticServiceImpl()

    private lazy var reachability: ReachabilityService = ReachabilityServiceImpl()
    private lazy var imageCache: ImageCache = DefaultImageCache.shared
    private lazy var urlSession: URLSession = .shared

    func makeChannelRepository() -> any ChannelRepository {
        #if DEBUG
        if let scenario = AppRuntime.stubScenario { return DeveloperStubRepository(scenario: scenario) }
        #endif
        return ChannelRepositoryImpl(
            api: IPTVAPIServiceImpl(client: CommonNetworkingHTTPClient()),
            cache: ChannelDiskCache()
        )
    }

    func makeChannelListViewModel(favorites: (any FavoriteChannelStoring)? = nil) -> ChannelListViewModel {
        let repository = makeChannelRepository()
        let fetchChannels = DefaultFetchChannelsUseCase(repository: repository)
        let filterChannels = DefaultFilterChannelsUseCase()
        let manageCache = DefaultManageChannelCacheUseCase(repository: repository)
        return ChannelListViewModel(
            fetchChannels: fetchChannels,
            filterChannels: filterChannels,
            manageCache: manageCache,
            reachability: reachability,
            haptics: haptics,
            favorites: favorites,
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

    func getURLSession() -> URLSession {
        urlSession
    }
}
