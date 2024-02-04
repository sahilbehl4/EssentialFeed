//
//  CodableFeedStore.swift
//  EssentialFeed
//
//  Created by Sahil Behl on 2024-01-01.
//

import Foundation

public final class CodableFeedStore: FeedStore {
    private struct Cache: Codable {
        let items: [CodableFeedImage]
        let timeStamp: Date
        
        
        var localFeed: [LocalFeedImage] {
            return items.map { $0.local }
        }
    }
    
    private struct CodableFeedImage: Codable {
        let id: UUID
        let description: String?
        let location: String?
        let url: URL
        
        var local: LocalFeedImage {
            return LocalFeedImage(id: id, description: description, location: location, url: url)
        }
        
        init(_ image: LocalFeedImage) {
            id = image.id
            description = image.description
            location = image.location
            url = image.url
        }
    }
    
    public init(storeURL: URL) {
        self.storeURL = storeURL
    }
    
    private let storeURL: URL
    
    public func delete() async throws {
        guard FileManager.default.fileExists(atPath: storeURL.path) else {
            return
        }
        
        try FileManager.default.removeItem(at: storeURL)
    }
    
    public func insert(items: [LocalFeedImage], timeStamp: Date) async throws {
        let cache = Cache(items: items.map(CodableFeedImage.init), timeStamp: timeStamp)
        let encodedData = try JSONEncoder().encode(cache)
        try encodedData.write(to: storeURL)
    }
    
    public func retrieve() async throws -> (Date?, [EssentialFeed.LocalFeedImage]) {
        guard let data = try? Data(contentsOf: storeURL) else {
            return (nil, [])
        }
        let cache = try JSONDecoder().decode(Cache.self, from: data)
        return (cache.timeStamp, cache.localFeed)
    }
}
