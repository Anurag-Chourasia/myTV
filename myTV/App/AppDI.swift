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

    private lazy var reachability: ReachabilityService = ReachabilityServiceImpl()

    private func makeChannelRepository() -> ChannelRepository {
        #if DEBUG
        if let scenario = AppRuntime.stubScenario { return DeveloperStubRepository(scenario: scenario) }
        #endif
        return ChannelRepositoryImpl(
            api: IPTVAPIServiceImpl(client: CommonNetworkingHTTPClient()),
            cache: ChannelDiskCache()
        )
    }

    func makeChannelListViewModel() -> ChannelListViewModel {
        let fetchChannels = DefaultFetchChannelsUseCase(
            repository: makeChannelRepository()
        )
        return ChannelListViewModel(
            fetchChannels: fetchChannels,
            reachability: reachability,
            haptics: haptics
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
