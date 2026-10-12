//
//  AppDI.swift
//  myTV
//
//  Created by Anurag Chourasia on 23/01/26.
//

final class AppDI {

    static let shared = AppDI()

    private lazy var haptics: HapticService =
            HapticServiceImpl()

    private lazy var httpClient: HTTPClient =
        CommonNetworkingHTTPClient()

    private lazy var reachability: ReachabilityService =
        ReachabilityServiceImpl()

    private lazy var apiService: IPTVAPIService =
        IPTVAPIServiceImpl(client: httpClient)

    private lazy var channelCache: ChannelCache =
        ChannelDiskCache()

    private lazy var channelRepository: ChannelRepository =
        ChannelRepositoryImpl(
            api: apiService,
            cache: channelCache
        )

    func makeChannelListViewModel() -> ChannelListViewModel {
        let fetchChannels = DefaultFetchChannelsUseCase(
            repository: channelRepository
        )
        return ChannelListViewModel(
            fetchChannels: fetchChannels,
            reachability: reachability,
            haptics: haptics
        )
    }

    func makeStreamListViewModel() -> StreamListViewModel {
        let fetchStreams = DefaultFetchStreamsForChannelUseCase(
            repository: channelRepository
        )
        return StreamListViewModel(
            fetchStreams: fetchStreams,
            reachability: reachability,
            haptics: haptics
        )
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
}
