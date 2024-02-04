//
//  FeedStoreSpy.swift
//  EssentialFeedTests
//
//  Created by Sahil Behl on 2023-11-06.
//

import EssentialFeed

class FeedStoreSpy: FeedStore {
    var insertErrorToThrow: NSError? = nil
    var deleteErrorToThrow: NSError? = nil
    
    var retrievedResult: Result<(Date?, [LocalFeedImage]), Error> = .failure(NSError(domain: "", code: 0))

    enum ReceivedMessage: Equatable {
        case retrieve
        case deleteCachedFeed
        case insert([LocalFeedImage], Date)
    }

    private(set) var receivedMessages = [ReceivedMessage]()

    func delete() async throws {
        receivedMessages.append(.deleteCachedFeed)
        if let deleteErrorToThrow {
            throw deleteErrorToThrow
        }
    }

    func insert(items: [LocalFeedImage], timeStamp: Date) async throws {
        receivedMessages.append(.insert(items, timeStamp))
        if let insertErrorToThrow {
            throw insertErrorToThrow
        }
    }
    
    func retrieve() throws -> (Date?, [LocalFeedImage]) {
        receivedMessages.append(.retrieve)
        
        switch retrievedResult {
        case .success(let success):
            return success
        case .failure(let error):
            throw error
        }
    }
}
