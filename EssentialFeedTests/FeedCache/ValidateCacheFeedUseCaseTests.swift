//
//  ValidateCacheFeedUseCaseTests.swift
//  EssentialFeedTests
//
//  Created by Sahil Behl on 2023-11-13.
//

import XCTest
import EssentialFeed

class ValidateCacheFeedUseCaseTests: XCTestCase {
    private var store: FeedStoreSpy!
    private var sut: LocalFeedLoader!
    
    override func setUp() {
        store = FeedStoreSpy()
        sut = LocalFeedLoader(store: store, currentDate: { Date() })
    }
    
    func test_init() {
        XCTAssertEqual(store.receivedMessages, [])
    }
    
    func test_validateCache_deletesCacheOnRetrievalError() async throws {
        let anyError = NSError(domain: "anyerror`", code: 0)
        store.retrievedResult = .failure(anyError)
            let _ = try await sut.validateCache()
            XCTAssertEqual(store.receivedMessages, [.retrieve, .deleteCachedFeed])
    }
    
    func test_validateCache_doesNotDeleteCacheOnEmptyCache() async throws {
        store.retrievedResult = .success((Date(), []))
        let _ = try await sut.validateCache()
        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }
    
    func test_validateCache_doesNotDeleteCacheOnNonExpiredCache() async throws {
        let feed = uniqueImageFeed()
        let nonExpiredTimestamp = Date().minusFeedCacheMaxAge().adding(days: 1)
        store.retrievedResult = .success((nonExpiredTimestamp, feed.local))

        let _ = try await sut.validateCache()
        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }
    
    func test_validateCache_deletesCacheOnSevenDaysOldCache() async throws {
        let feed = uniqueImageFeed()
        let expiredTimestamp = Date().minusFeedCacheMaxAge()
        store.retrievedResult = .success((expiredTimestamp, feed.local))

        let _ = try await sut.validateCache()
        XCTAssertEqual(store.receivedMessages, [.retrieve, .deleteCachedFeed])
    }
    
    func test_validateCache_deletesCacheOnMoreThanSevenDaysOldCache() async throws {
        let feed = uniqueImageFeed()
        let expiredTimestamp = Date().minusFeedCacheMaxAge().adding(days: -1)
        store.retrievedResult = .success((expiredTimestamp, feed.local))

        let _ = try await sut.validateCache()
        XCTAssertEqual(store.receivedMessages, [.retrieve, .deleteCachedFeed])
    }
}

