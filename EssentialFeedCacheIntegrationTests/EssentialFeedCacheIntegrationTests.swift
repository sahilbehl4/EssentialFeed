//
//  EssentialFeedCacheIntegrationTests.swift
//  EssentialFeedCacheIntegrationTests
//
//  Created by Sahil Behl on 2024-01-29.
//

import XCTest
import EssentialFeed

final class EssentialFeedCacheIntegrationTests: XCTestCase {
    override func setUp() {
        deleteStoreArtifacts()
    }
    
    override func tearDown() {
        deleteStoreArtifacts()
    }
    
    private func testSpecificStoreURL() -> URL {
        return cachesDirectory().appendingPathComponent("\(type(of: self)).store")
    }
    
    private func cachesDirectory() -> URL {
        return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
    }
    
    func test_load_deliversNoItemsOnEmptyCache() async {
        await expect(makeSUT(), toLoad: [])
    }
    
    func test_load_deliversItemsSavedOnASeparateInstance() async {
        let sutToPerformSave = makeSUT()
        let sutToPerformLoad = makeSUT()
        let feed = [createUniqueFeedItem(), createUniqueFeedItem()]
        
        await save(feed, with: sutToPerformSave)
        
        await expect(sutToPerformLoad, toLoad: feed)
    }
    
    func test_save_overridesItemsSavedOnASeparateInstance() async {
        let sutToPerformFirstSave = makeSUT()
        let sutToPerformLastSave = makeSUT()
        let sutToPerformLoad = makeSUT()
        let firstFeed = [createUniqueFeedItem(), createUniqueFeedItem()]
        let latestFeed = [createUniqueFeedItem(), createUniqueFeedItem(), createUniqueFeedItem()]
        
        await save(firstFeed, with: sutToPerformFirstSave)
        await save(latestFeed, with: sutToPerformLastSave)
        
        await expect(sutToPerformLoad, toLoad: latestFeed)
    }
    
    // MARK: Helpers
    
    private func makeSUT(file: StaticString = #file, line: UInt = #line) -> LocalFeedLoader {
        let storeBundle = Bundle(for: CoreDataFeedStore.self)
        let storeURL = testSpecificStoreURL()
        let store = try! CoreDataFeedStore(storeURL: storeURL, bundle: storeBundle)
        let sut = LocalFeedLoader(store: store, currentDate: Date.init)
        return sut
    }
    
    private func save(_ feed: [FeedImage], with loader: LocalFeedLoader, file: StaticString = #file, line: UInt = #line) async {
        do {
            try await loader.save(feed)
            XCTAssertTrue(true, "save feed successfully", file: file, line: line)
        } catch {
            XCTFail("Expected to save feed successfully", file: file, line: line)
        }
    }
    
    private func expect(_ sut: LocalFeedLoader, toLoad expectedFeed: [FeedImage], file: StaticString = #file, line: UInt = #line) async {
        do {
            let loadedFeed = try await sut.load()
            XCTAssertEqual(loadedFeed, expectedFeed, file: file, line: line)
        } catch {
            XCTFail("Expected successful feed result, got \(error) instead", file: file, line: line)
        }
    }
    
    private func deleteStoreArtifacts() {
        try? FileManager.default.removeItem(at: testSpecificStoreURL())
    }
    
    private func createUniqueFeedItem() -> FeedImage {
        FeedImage(id: UUID(), description: nil, location: nil, imageURL: URL(string: "www.google.ca")!)
    }

}
