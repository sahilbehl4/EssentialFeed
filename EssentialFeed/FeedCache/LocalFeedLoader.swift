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

    public func save(_ items: [FeedItem]) async throws {
        try await store.delete()
        try await store.insert(items: items, timeStamp: currentDate())
    }
}
