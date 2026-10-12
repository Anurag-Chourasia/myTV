import Foundation
func adapterDTOCalls(_ client: CommonNetworkingHTTPClient, url: URL) async throws {
    let _: [ChannelDTO] = try await client.get(url)
    let _: [LogoDTO] = try await client.get(url)
    let _: [StreamDTO] = try await client.get(url)
    async let channels: [ChannelDTO] = client.get(url)
    async let logos: [LogoDTO] = client.get(url)
    _ = try await (channels, logos)
    _ = try await client.getRaw(url)
}
