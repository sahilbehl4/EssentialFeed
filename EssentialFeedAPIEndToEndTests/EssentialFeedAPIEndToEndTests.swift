//
//  EssentialFeedAPIEndToEndTests.swift
//  EssentialFeedAPIEndToEndTests
//
//  Created by Sahil Behl on 8/7/23.
//

import XCTest
import EssentialFeed

final class EssentialFeedAPIEndToEndTests: XCTestCase {

    func test_endToEndServer_matchesFixedTestAccountData() {
        let result = getFeedResult()
        switch result {
        case .success(let items):
            XCTAssertEqual(items.count, 8)
        default:
            XCTFail()
        }
    }

    private func getFeedResult(file: StaticString = #file, line: UInt = #line) -> Result<[FeedItem], Error>? {
        let testServerURL = URL(string: "https://essentialdeveloper.com/feed-case-study/test-api/feed")!
        let client = URLSessionHTTPClient()
        let loader = RemoteFeedLoader(url: testServerURL, httpClient: client)

        let exp = expectation(description: "Wait for load completion")

        var receivedResult:Result<[FeedItem], Error>?
        loader.load { result in
            receivedResult = result
            exp.fulfill()
        }
        wait(for: [exp], timeout: 5.0)

        return receivedResult
    }

}
