//
//  LocalFeedFromCacheUseCases.swift
//  EssentialFeedTests
//
//  Created by Sahil Behl on 2023-11-05.
//

import XCTest
import EssentialFeed

class LocalFeedFromCacheUseCaseTests: XCTestCase {
    private var store: FeedStoreSpy!
    private var sut: LocalFeedLoader!
    
    override func setUp() {
        store = FeedStoreSpy()
        sut = LocalFeedLoader(store: store, currentDate: { Date() })
    }
    
    func test_init() {
        XCTAssertEqual(store.receivedMessages, [])
    }
    
    func test_load_requestCacheRetreival() async throws {
        store.retrievedResult = .success((Date(), []))
        _ = try await sut.load()
        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }
    
    func test_load_failsOnRetreivealError() async {
        let anyError = NSError(domain: "anyerror`", code: 0)
        store.retrievedResult = .failure(anyError)
        do {
            _ = try await sut.load()
            XCTFail()
        } catch {
            XCTAssertEqual(error as NSError, anyError)
        }
    }
    
    func test_load_deliversNoImagesOnEmptyCache() async throws {
        store.retrievedResult = .success((Date(), []))
        let images = try await sut.load()
        XCTAssertEqual(images, [])
    }
    
    func test_load_deliversImagesOnNonExpiredCache() async throws {
        let feed = uniqueImageFeed()
        let nonExpiredTimestamp = Date().minusFeedCacheMaxAge().adding(days: 1)
        store.retrievedResult = .success((nonExpiredTimestamp, feed.local))

        let images = try await sut.load()
        XCTAssertEqual(images, feed.models)
    }
    
    func test_load_deliversErrorOnCacheExpiration() async throws {
        let feed = uniqueImageFeed()
        let expiredTimestamp = Date().minusFeedCacheMaxAge()
        store.retrievedResult = .success((expiredTimestamp, feed.local))
        
        let images = try await sut.load()
        XCTAssertEqual(images, [])
    }
    
    func test_load_deliversErrorOnExpiredCache() async throws {
        let feed = uniqueImageFeed()
        let expiredTimestamp = Date().minusFeedCacheMaxAge().adding(seconds: -1)
        store.retrievedResult = .success((expiredTimestamp, feed.local))
        
        let images = try await sut.load()
        XCTAssertEqual(images, [])
    }
    
    func test_load_hasNoSideEffectsOnRetrievalError() async throws {
        let anyError = NSError(domain: "anyerror`", code: 0)
        store.retrievedResult = .failure(anyError)
        do {
            let _ = try await sut.load()
        } catch {
            XCTAssertEqual(store.receivedMessages, [.retrieve])
        }
    }
    
    func test_load_hasNoSideEffectsOnEmptyCache() async throws {
        store.retrievedResult = .success((Date(), []))
        let _ = try await sut.load()
        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }
    
    func test_load_hasNoSideEffectsOnLessThanSevenDaysOldCache() async throws {
        let feed = uniqueImageFeed()
        let lessThanSevenDaysOldDate = Date().adding(days: -7).adding(days: 1)
        store.retrievedResult = .success((lessThanSevenDaysOldDate, feed.local))

        let _ = try await sut.load()
        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }
    
    func test_load_hasNoSideEffectsOnLSevenDaysOldCache() async throws {
        let feed = uniqueImageFeed()
        let lessThanSevenDaysOldDate = Date().adding(days: -7)
        store.retrievedResult = .success((lessThanSevenDaysOldDate, feed.local))

        let _ = try await sut.load()
        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }
    
    func test_load_deletesCacheOnMoreThanSevenDaysOldCache() async throws {
        let feed = uniqueImageFeed()
        let lessThanSevenDaysOldDate = Date().adding(days: -7).adding(days: -1)
        store.retrievedResult = .success((lessThanSevenDaysOldDate, feed.local))

        let _ = try await sut.load()
        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }
    
    func test_storeSideEffects_runSerially() {
        
    }
}
