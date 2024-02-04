//
//  EssentialFeedAPIEndToEndTests.swift
//  EssentialFeedAPIEndToEndTests
//
//  Created by Sahil Behl on 8/7/23.
//

import XCTest
import EssentialFeed

final class EssentialFeedAPIEndToEndTests: XCTestCase {

    func test_endToEndServer_matchesFixedTestAccountData() async throws {
        do {
            let items = try await getFeedResult()
            XCTAssertEqual(items.count, 8)
        } catch {
            XCTFail()
        }
    }

    private func getFeedResult(file: StaticString = #file, line: UInt = #line) async throws -> [FeedImage] {
        let testServerURL = URL(string: "https://essentialdeveloper.com/feed-case-study/test-api/feed")!
        let client = URLSessionHTTPClient()
        let loader = RemoteFeedLoader(url: testServerURL, httpClient: client)
        
        return try await loader.load()

    }

}
