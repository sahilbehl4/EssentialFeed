//
//  CacheFeedLocalTests.swift
//  EssentialFeedTests
//
//  Created by Sahil Behl on 8/20/23.
//

import XCTest
import EssentialFeed

final class CacheFeedLocalTests: XCTestCase {
    private var store: FeedStoreSpy!
    private var sut: LocalFeedLoader!

    override func setUp() {
        store = FeedStoreSpy()
        sut = LocalFeedLoader(store: store, currentDate: { Date() })
    }

    func test_save_doesNotRequestCacheInsertionWhenDeletionErrors() async throws {
        let items = [createUniqueFeedItem(), createUniqueFeedItem()]
        store.deleteErrorToThrow = NSError(domain: "0", code: 0)

        try? await sut.save(items)

        XCTAssertEqual(store.receivedMessages, [.deleteCachedFeed])
    }

    func test_save_failsWhenDeletionErrors() async throws {
        let items = [createUniqueFeedItem(), createUniqueFeedItem()]
        let deletionError = NSError(domain: "deletion", code: 0)
        store.deleteErrorToThrow = deletionError

        do {
            try await sut.save(items)
        } catch {
            XCTAssertEqual(error as NSError, deletionError)
        }
    }

    func test_save_failsWhenInsertionErrors() async throws {
        let items = [createUniqueFeedItem(), createUniqueFeedItem()]
        let insertionError = NSError(domain: "insertion", code: 0)

        store.insertErrorToThrow = insertionError

        do {
            try await sut.save(items)
        } catch {
            XCTAssertEqual(error as NSError, insertionError)
        }
    }


    func test_save_requestsCacheInsertion() async throws {
        let timestamp = Date()
        let items: [FeedItem] = [createUniqueFeedItem(), createUniqueFeedItem()]
        sut = LocalFeedLoader(store: store, currentDate: { timestamp })
        try await sut.save(items)

        XCTAssertEqual(store.receivedMessages.first, .deleteCachedFeed)
        XCTAssertEqual(store.receivedMessages.last, .insert(items, timestamp))

    }

    private func createUniqueFeedItem() -> FeedItem {
        FeedItem(id: UUID(), description: nil, location: nil, imageURL: URL(string: "www.google.ca")!)
    }

    class FeedStoreSpy: FeedStore {
        var insertErrorToThrow: NSError? = nil
        var deleteErrorToThrow: NSError? = nil

        enum ReceivedMessage: Equatable {
            case deleteCachedFeed
            case insert([FeedItem], Date)
        }

        private(set) var receivedMessages = [ReceivedMessage]()

        func delete() async throws {
            receivedMessages.append(.deleteCachedFeed)
            if let deleteErrorToThrow {
                throw deleteErrorToThrow
            }
        }

        func insert(items: [FeedItem], timeStamp: Date) async throws {
            receivedMessages.append(.insert(items, timeStamp))
            if let insertErrorToThrow {
                throw insertErrorToThrow
            }
        }
    }
}
