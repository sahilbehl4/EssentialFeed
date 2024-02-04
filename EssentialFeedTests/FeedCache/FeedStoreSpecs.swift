//
//  FeedStoreSpecs.swift
//  EssentialFeedTests
//
//  Created by Sahil Behl on 2024-01-01.
//

import Foundation

protocol FeedStoreSpecs {
    func test_retrieve_deliversEmptyOnEmptyCache() async throws
    func test_retrieve_hasNoSideEffectsOnEmptyCache() async throws
    func test_retrieveAfterInsertingToEmptyCache_deliversInsertedValues() async throws
    func test_retrieve_hasNoSideEffectsOnNONEmptyCache() async throws

    func test_insert_overridesPreviousData() async throws

    func test_delete_emptiesPreviousInsertedCache() async throws
    func test_delete_hasNoSideEffectsOnEmptyCache() async throws
}

protocol FailableRetreiveFeedStoreSpecs: FeedStoreSpecs {
    func test_retrieve_deliversErrorOnRetrievalError() async throws
    func test_retrieve_noSideEffectsOnFailure() async throws
}

protocol FailableInsertionFeedStoreSpecs: FeedStoreSpecs {
    func test_insert_deliversErrorOnWritingIntoInvalidURL() async throws
}


protocol FailableDeletionFeedStoreSpecs: FeedStoreSpecs {
    func test_delete_deliversErrorOnDeletionError() async throws
}

typealias FailableFeedStoreSpecs = FailableRetreiveFeedStoreSpecs & FailableInsertionFeedStoreSpecs & FailableDeletionFeedStoreSpecs
