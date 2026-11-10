//
//  ChannelDiskCache.swift
//  myTV
//
//  Created by Anurag Chourasia on 23/01/26.
//

import Foundation
import FoundationKit

final class ChannelDiskCache: ChannelCache {

    private let fileURL: URL
    private let byteFormatter: any ByteCountFormatting
    private let logger: any AppLogger
    private let clock: any AppClock

    init(
        fileURL: URL? = nil,
        byteFormatter: (any ByteCountFormatting)? = nil,
        logger: (any AppLogger)? = nil,
        clock: (any AppClock)? = nil
    ) {
        if let fileURL {
            self.fileURL = fileURL
        } else {
            let directory = FileManager.default.urls(
                for: .cachesDirectory,
                in: .userDomainMask
            ).first ?? URL(fileURLWithPath: NSTemporaryDirectory())
            self.fileURL = directory.appendingPathComponent("channels_cache.json")
        }
        self.byteFormatter = byteFormatter ?? ByteCountFormatterFactory.make()
        self.logger = logger ?? UnifiedLogger(subsystem: "com.mytv.cache", category: "disk")
        self.clock = clock ?? SystemClock()
    }

    var entryCount: Int {
        load()?.count ?? 0
    }

    var fileSizeBytes: Int {
        (try? FileManager.default.attributesOfItem(atPath: fileURL.path)[.size] as? Int) ?? 0
    }

    var formattedFileSize: String {
        byteFormatter.string(fromByteCount: fileSizeBytes)
    }

    func save(_ channels: [ChannelDTO]) {
        do {
            let data = try JSONEncoder().encode(channels)
            try data.write(to: fileURL, options: [.atomic])
        } catch {
            logger.log("Failed to save channel cache: \(error.localizedDescription)", level: .error)
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
