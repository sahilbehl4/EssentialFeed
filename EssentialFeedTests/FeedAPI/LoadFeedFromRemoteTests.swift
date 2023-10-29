//
//  LoadFeedFromRemoteTests.swift
//  EssentialFeedTests
//
//  Created by Sahil Behl on 6/21/23.
//

import XCTest

import EssentialFeed

class LoadFeedFromRemoteTests: XCTestCase {

    var sut: RemoteFeedLoader!
    var client: HTTPClientSpy!
    var url: URL!

    override func setUp() async throws {
        url = URL(string: "www.google.ca")!
        client = HTTPClientSpy()
        sut = RemoteFeedLoader(url: url, httpClient: client)
    }

    func test_load_doesNotRequestDataFromURL() {
        XCTAssertEqual(client.messages.compactMap { $0.0 }, [])
    }

    func test_load_requestDataFromURL() {
        sut.load() { _ in }

        let urls = client.messages.compactMap { $0.0 }

        XCTAssertEqual(urls, [url])
        XCTAssertEqual(urls.count, 1)
    }

    func test_loadTwice_requestDataFromURLTwice() {
        sut.load() { _ in }
        sut.load() { _ in }

        let urls = client.messages.compactMap { $0.0 }

        XCTAssertEqual(urls, [url, url])
        XCTAssertEqual(urls.count, 2)
    }

    func test_load_deliversErrorOnClientError() {
        expect(sut, toCompleteWith: .failure(.connectivity)) {
            client.completeWith(error: NSError())
        }
    }

    func test_load_deliversErrorOnNon200ErrorResponse() throws {
        let emptyData = try makeJSONItems([])

        // Assert
        expect(sut, toCompleteWith: .failure(.invalidData)) {
            client.completeWith(withStatusCode: 400, data: emptyData, at: 0)
        }
    }

    func test_load_deliversErrorOn200ResponseButInvalidData() {
        let invalidData = Data("Invalid data".utf8)

        // Assert
        expect(sut, toCompleteWith: .failure(.invalidData)) {
            client.completeWith(withStatusCode: 200, data: invalidData, at: 0)

        }
    }

    func test_load_deliversNoItemsOn200ResponseWithEmptyList() throws {
        let emptyData = try makeJSONItems([])

        // Assert
        expect(sut, toCompleteWith: .success([])) {
            client.completeWith(withStatusCode: 200, data: emptyData, at: 0)
        }
    }

    func test_load_deliversItemsOn200ResponseWithJSONItems() throws {
        let (jsonItem1, item1) = makeItem(id: UUID(), imageURL: "www.google.ca")
        let (jsonItem2, item2) = makeItem(id: UUID(), imageURL: "www.yahoo.ca")

        let data = try makeJSONItems([jsonItem1, jsonItem2])

        // Assert

        expect(sut, toCompleteWith: .success([item1, item2])) {
            client.completeWith(withStatusCode: 200, data: data, at: 0)
        }
    }

    func test_MemoryLeak() {
        let sutLeak = RemoteFeedLoader(url: url, httpClient: client)
        addTeardownBlock { [weak sutLeak] in
            XCTAssertNil(sutLeak)
        }
    }

    func test_load_doesNotDeliverAfterDeallocating() {
        var sutLeak: RemoteFeedLoader? = RemoteFeedLoader(url: url, httpClient: client)

        var capturedResult: Result<[FeedItem], Error>?

        sutLeak?.load { result in
            capturedResult = result
        }

        sutLeak = nil

        client.completeWith(error: RemoteFeedLoader.Error.invalidData)

        XCTAssertNil(capturedResult)
    }

    func expect(_ sut: RemoteFeedLoader, toCompleteWith result: Result<[FeedItem], RemoteFeedLoader.Error>, when act: () -> Void, file: StaticString = #filePath, line: UInt = #line) {


        sut.load { receivedResult in
            switch (receivedResult, result) {
            case let (.success(items), .success(expectedItems)):
                XCTAssertEqual(items, expectedItems, file: file, line: line)
            case let (.failure(error), .failure(expectedError)):
                XCTAssertEqual(error.localizedDescription, expectedError.localizedDescription, file: file, line: line)
            default:
                XCTFail("")
            }
        }

        act()
    }

    func makeJSONItems(_ jsonItems: [[String: Any]]) throws -> Data {
        let itemsJson = [
            "items": jsonItems
        ]
        let data = try JSONSerialization.data(withJSONObject: itemsJson)
        return data
    }

    func makeItem(
        id: UUID,
        description: String? = nil,
        location: String? = nil,
        imageURL: String
    ) -> ([String: Any], FeedItem) {
        let item = FeedItem(
            id: id,
            description: description,
            location: location,
            imageURL: URL(string: imageURL)!
        )

        let jsonItem = [
            "id": id.uuidString,
            "description": description,
            "location": location,
            "image": imageURL
        ].compactMapValues {
            $0
        }

        return (jsonItem, item)
    }

}

class HTTPClientSpy: HTTPClient {
    var messages: [(URL, (Result<(HTTPURLResponse, Data), Error>) -> Void)] = []

    func get(from url: URL, completion: @escaping ((Result<(HTTPURLResponse, Data), Error>) -> Void)) {
        messages.append((url, completion))
    }

    func completeWith(error: Error, at index: Int = 0) {
        messages[index].1(.failure(error))
    }

    func completeWith(withStatusCode statusCode: Int, data: Data, at index: Int = 0) {
        let response = HTTPURLResponse(
            url: messages[index].0,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: nil
        )!

        messages[index].1(.success((response, data)))
    }
}
