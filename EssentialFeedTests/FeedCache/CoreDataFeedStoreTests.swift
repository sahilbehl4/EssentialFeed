//
//  CoreDataFeedStoreTests.swift
//  EssentialFeedTests
//
//  Created by Sahil Behl on 2024-01-29.
//

import XCTest
import EssentialFeed

class CoreDataFeedStoreTests: XCTestCase, FeedStoreSpecs {
    var sut: CoreDataFeedStore!
    
    override func setUp() async throws {
        let storeBundle = Bundle(for: CoreDataFeedStore.self)
        let storeURL = URL(filePath: "/dev/null")
        sut = try CoreDataFeedStore(storeURL: storeURL, bundle: storeBundle)
    }
    
    func test_retrieve_deliversEmptyOnEmptyCache() async throws {
        let (timeStamp, feed) = try await sut.retrieve()
        XCTAssertNil(timeStamp)
        XCTAssertEqual(feed, [])
    }
    
    func test_retrieve_hasNoSideEffectsOnEmptyCache() async throws {
        let result1 = try await sut.retrieve()
        let result2 = try await sut.retrieve()
        
        XCTAssertNil(result1.0)
        XCTAssertEqual(result1.1, [])
        
        XCTAssertNil(result2.0)
        XCTAssertEqual(result2.1, [])
    }
    
    func test_retrieveAfterInsertingToEmptyCache_deliversInsertedValues() async throws {
        let feed = uniqueImageFeed().local
        let timeStamp = Date()
        
        try await sut.insert(items: feed, timeStamp: timeStamp)
        
        let result = try await sut.retrieve()
        
        XCTAssertEqual(result.0, timeStamp)
        XCTAssertEqual(result.1, feed)
    }
    
    func test_retrieve_hasNoSideEffectsOnNONEmptyCache() async throws {
        let feed = uniqueImageFeed().local
        let timeStamp = Date()
        
        try await sut.insert(items: feed, timeStamp: timeStamp)
        
        let result1 = try await sut.retrieve()
        let result2 = try await sut.retrieve()
        
        XCTAssertEqual(result1.0, timeStamp)
        XCTAssertEqual(result1.1, feed)
        
        XCTAssertEqual(result2.0, timeStamp)
        XCTAssertEqual(result2.1, feed)
    }
    
    func test_insert_overridesPreviousData() async throws {
        let timeStamp = Date()
        try await sut.insert(items: uniqueImageFeed().local, timeStamp: timeStamp)
        
        let latestTimeStamp = Date()
        try await sut.insert(items: uniqueImageFeed().local, timeStamp: latestTimeStamp)

        let result = try? await sut.retrieve()
        XCTAssertEqual(result?.0, latestTimeStamp)
    }
    
    func test_delete_emptiesPreviousInsertedCache() async throws {
        try await sut.insert(items: uniqueImageFeed().local, timeStamp: Date())
        
        try await sut.delete()
        
        let result = try await sut.retrieve()
        XCTAssertNil(result.0)
        XCTAssertEqual(result.1, [])
    }
    
    func test_delete_hasNoSideEffectsOnEmptyCache() async throws {
        try await sut.delete()
        let result = try await sut.retrieve()
        XCTAssertNil(result.0)
        XCTAssertEqual(result.1, [])
    }
}
