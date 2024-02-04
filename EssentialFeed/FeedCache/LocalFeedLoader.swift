//
//  LocalFeedLoader.swift
//  EssentialFeed
//
//  Created by Sahil Behl on 8/27/23.
//

import Foundation

public struct LocalFeedLoader {
    private let store: FeedStore
    private let currentDate: () -> Date
    
    public init(store: FeedStore, currentDate: @escaping () -> Date) {
        self.store = store
        self.currentDate = currentDate
    }
}

extension LocalFeedLoader: FeedLoader {
    public func load() async throws -> [FeedImage] {
        do {
            let (cacheDate, feed) = try await store.retrieve()
            guard let cacheDate = cacheDate,
                    FeedCachePolicy.validate(cacheDate, against: currentDate()) else {
                return []
            }
            return feed.toFeed()
        } catch {
            throw error
        }
    }
}

extension LocalFeedLoader {
    public func save(_ items: [FeedImage]) async throws {
        try await store.delete()
        try await store.insert(items: items.toLocal(), timeStamp: currentDate())
    }
}

extension LocalFeedLoader {
    public func validateCache() async throws {
        do {
            guard let cacheDate  = try await store.retrieve().0 else {
                return
            }
            if !FeedCachePolicy.validate(cacheDate, against: currentDate()) {
                try await store.delete()
            }
        } catch {
            try await store.delete()
        }
    }
}

private extension Array where Element == FeedImage {
    func toLocal() -> [LocalFeedImage] {
        return map {
            LocalFeedImage(id: $0.id, description: $0.description, location: $0.location, url: $0.imageURL)
        }
    }
}

private extension Array where Element == LocalFeedImage {
    func toFeed() -> [FeedImage] {
        return map {
            FeedImage(id: $0.id, description: $0.description, location: $0.location, imageURL: $0.url)
        }
    }
}
