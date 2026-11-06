import Foundation

/// Account IDs come from authentication, never from email or display names.
/// A single preference write commits the legacy claim together with its copied IDs.
struct FavoriteChannelStore {
    private static let lock = NSLock()
    private let defaults: UserDefaults
    private let ownerID: String?
    private let key = "favoriteChannelIDs.owners.v1"
    private let legacyKey = "favoriteChannelIDs"

    init(defaults: UserDefaults = .standard, ownerID: UUID? = nil) {
        self.defaults = defaults
        self.ownerID = ownerID?.uuidString.lowercased()
    }

    func load() -> Set<String> {
        Self.lock.lock()
        defer { Self.lock.unlock() }
        guard var state = state() else { return [] }
        migrateLegacy(into: &state)
        return Set(state[ownerID ?? "guest"] ?? [])
    }

    func save(_ ids: Set<String>) {
        Self.lock.lock()
        defer { Self.lock.unlock() }
        guard var state = state() else { return }
        migrateLegacy(into: &state)
        state[ownerID ?? "guest"] = ids.sorted()
        defaults.set(state, forKey: key)
    }

    private func state() -> [String: [String]]? {
        guard let value = defaults.object(forKey: key) else { return [:] }
        // Preserve an unreadable envelope for recovery rather than overwriting it.
        return value as? [String: [String]]
    }

    private func migrateLegacy(into state: inout [String: [String]]) {
        guard state["legacyOwner"] == nil else { return }
        let legacy = Set(defaults.stringArray(forKey: legacyKey) ?? [])
        let unclaimed = state["guest"].map { Set($0) } ?? legacy
        if let ownerID {
            state[ownerID] = Set(state[ownerID] ?? []).union(unclaimed).sorted()
            state["legacyOwner"] = [ownerID]
            state["guest"] = []
        } else if state["guest"] == nil {
            state["guest"] = unclaimed.sorted()
        } else {
            return
        }
        // Keep the old key unchanged as a nondestructive migration backup.
        defaults.set(state, forKey: key)
    }
}
