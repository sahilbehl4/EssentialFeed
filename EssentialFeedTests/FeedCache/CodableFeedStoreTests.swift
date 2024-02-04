//
//  CodableFeedStoreTests.swift
//  EssentialFeedTests
//
//  Created by Sahil Behl on 2023-12-10.
//

import XCTest
import EssentialFeed

class CodableFeedStoreTests: XCTestCase, FeedStoreSpecs, FailableFeedStoreSpecs {
    
    var sut: FeedStore!
    var storeURL: URL!
    
    override func setUp() {
        storeURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appending(component: "\(type(of: self)).store")
        try? FileManager.default.removeItem(at: storeURL)
        
        sut = CodableFeedStore(storeURL: storeURL)
    }
    
    override func tearDown() {
        let storeURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appending(component: "\(type(of: self)).store")
        
        try? FileManager.default.removeItem(at: storeURL!)
    }
    
    func test_retrieve_deliversEmptyOnEmptyCache() async throws {
        let result = try await sut.retrieve()
        
        XCTAssertNil(result.0)
        XCTAssertEqual(result.1, [])
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
    
    func test_retrieve_deliversErrorOnRetrievalError() async throws {
        try "invalidData".write(to: storeURL, atomically: false, encoding: .utf8)
        
        do {
            _ = try await sut.retrieve()
            XCTFail()
        } catch {
            XCTAssertTrue(true)
        }
    }
    
    func test_retrieve_noSideEffectsOnFailure() async throws {
        try "invalidData".write(to: storeURL, atomically: false, encoding: .utf8)
        
        do {
            _ = try await sut.retrieve()
            XCTFail()
        } catch {
            XCTAssertTrue(true)
        }
        
        do {
            _ = try await sut.retrieve()
            XCTFail()
        } catch {
            XCTAssertTrue(true)
        }
    }
    
    func test_insert_overridesPreviousData() async throws {
        let timeStamp = Date()
        try await sut.insert(items: uniqueImageFeed().local, timeStamp: timeStamp)
        
        let latestTimeStamp = Date()
        try await sut.insert(items: uniqueImageFeed().local, timeStamp: latestTimeStamp)
        
        let result = try? await sut.retrieve()
        XCTAssertEqual(result?.0, latestTimeStamp)
    }
    
    func test_insert_deliversErrorOnWritingIntoInvalidURL() async throws {
        let invalidURL = URL(string: "invalid://store-url")!
        sut = CodableFeedStore(storeURL: invalidURL)
        do {
            try await sut.insert(items: uniqueImageFeed().local, timeStamp: Date())
            XCTFail()
        } catch {
            XCTAssertTrue(true)
        }
    }
    
    func test_delete_hasNoSideEffectsOnEmptyCache() async throws {
        try await sut.delete()
        let result = try await sut.retrieve()
        XCTAssertNil(result.0)
        XCTAssertEqual(result.1, [])
    }
    
    func test_delete_emptiesPreviousInsertedCache() async throws {
        try await sut.insert(items: uniqueImageFeed().local, timeStamp: Date())
        
        try await sut.delete()
        
        let result = try await sut.retrieve()
        XCTAssertNil(result.0)
        XCTAssertEqual(result.1, [])
    }
    
    func test_delete_deliversErrorOnDeletionError() async throws {
        let cacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        sut = CodableFeedStore(storeURL: cacheDirectory)
        do {
            try await sut.delete()
            XCTFail()
        } catch {
            XCTAssertTrue(true)
        }
    }
}

