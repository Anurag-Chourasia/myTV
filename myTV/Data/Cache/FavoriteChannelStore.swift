import Foundation

/// Save at each edit, independently of the downloadable channel cache.
struct FavoriteChannelStore {
    private let defaults: UserDefaults
    private let key = "favoriteChannelIDs"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> Set<String> {
        Set(defaults.stringArray(forKey: key) ?? [])
    }

    func save(_ ids: Set<String>) {
        defaults.set(ids.sorted(), forKey: key)
    }
}
