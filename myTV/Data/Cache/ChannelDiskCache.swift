//
//  ChannelDiskCache.swift
//  myTV
//
//  Created by Anurag Chourasia on 23/01/26.
//

import Foundation

final class ChannelDiskCache: ChannelCache {

    private let fileURL: URL

    init() {
        let directory = FileManager.default.urls(
            for: .cachesDirectory,
            in: .userDomainMask
        ).first!

        self.fileURL = directory.appendingPathComponent("channels_cache.json")
    }

    var entryCount: Int {
        load()?.count ?? 0
    }

    var fileSizeBytes: Int {
        (try? FileManager.default.attributesOfItem(atPath: fileURL.path)[.size] as? Int) ?? 0
    }

    var formattedFileSize: String {
        let bytes = fileSizeBytes
        guard bytes > 0 else { return "0 KB" }
        return ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .file)
    }

    func save(_ channels: [ChannelDTO]) {
        do {
            let data = try JSONEncoder().encode(channels)
            try data.write(to: fileURL, options: [.atomic])
        } catch {
            // Optional: log error
            print("❌ Failed to save channel cache:", error)
        }
    }

    func load() -> [ChannelDTO]? {
        do {
            let data = try Data(contentsOf: fileURL)
            return try JSONDecoder().decode([ChannelDTO].self, from: data)
        } catch {
            return nil
        }
    }

    func clear() {
        try? FileManager.default.removeItem(at: fileURL)
    }
}
