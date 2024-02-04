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
    var client: HTTPClientStub!
    var url: URL!

    override func setUp() async throws {
        url = URL(string: "www.google.ca")!
        client = HTTPClientStub()
        sut = RemoteFeedLoader(url: url, httpClient: client)
    }

    func test_load_deliversErrorOnClientError() async throws  {
        await expect(sut, toCompleteWith: .failure(.connectivity)) {
            client.stub(error: NSError())
        }
    }

    func test_load_deliversErrorOnNon200ErrorResponse() async throws  {
        let emptyData = try makeJSONItems([])

        // Assert
        await expect(sut, toCompleteWith: .failure(.invalidData)) {
            client.stub(data: emptyData, statusCode: 400)
        }
    }

    func test_load_deliversErrorOn200ResponseButInvalidData() async throws  {
        let invalidData = Data("Invalid data".utf8)

        // Assert
        await expect(sut, toCompleteWith: .failure(.invalidData)) {
            client.stub(data: invalidData, statusCode: 200)

        }
    }

    func test_load_deliversNoItemsOn200ResponseWithEmptyList() async throws  {
        let emptyData = try makeJSONItems([])

        // Assert
        await expect(sut, toCompleteWith: .success([])) {
            client.stub(data: emptyData, statusCode: 200)
        }
    }

    func test_load_deliversItemsOn200ResponseWithJSONItems() async throws  {
        let (jsonItem1, item1) = makeItem(id: UUID(), imageURL: "www.google.ca")
        let (jsonItem2, item2) = makeItem(id: UUID(), imageURL: "www.yahoo.ca")

        let data = try makeJSONItems([jsonItem1, jsonItem2])

        // Assert

        await expect(sut, toCompleteWith: .success([item1, item2])) {
            client.stub(data: data, statusCode: 200)
        }
    }

    func test_MemoryLeak() {
        let sutLeak = RemoteFeedLoader(url: url, httpClient: client)
        addTeardownBlock { [weak sutLeak] in
            XCTAssertNil(sutLeak)
        }
    }

    func expect(_ sut: RemoteFeedLoader, toCompleteWith result: Result<[FeedImage], RemoteFeedLoader.Error>, when act: () -> Void, file: StaticString = #filePath, line: UInt = #line) async {
        
        act()

        do {
            let items = try await sut.load()
            
            if case .success(let expectedItems) = result {
                XCTAssertEqual(items, expectedItems, file: file, line: line)
            } else {
                XCTFail()
            }
        } catch {
            if case .failure(let expectedError) = result, let error = error as? RemoteFeedLoader.Error {
                XCTAssertEqual(error.localizedDescription, expectedError.localizedDescription, file: file, line: line)
            } else {
                XCTFail()
            }
        }
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
    ) -> ([String: Any], FeedImage) {
        let item = FeedImage(
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

class HTTPClientStub: HTTPClient {
    private struct Stub {
        let result: (Data, Int)?
        let error: Error?
    }
    
    private var stub: Stub?
    
    func stub(data: Data, statusCode: Int) {
        stub = Stub(result: (data, statusCode), error: nil)
    }
    
    func stub(error: Error) {
        stub = Stub(result: nil, error: error)
    }
    
    func get(from url: URL) async throws -> (Data, HTTPURLResponse) {
        if let error = stub?.error {
            throw error
        }
        
        if let (data, statusCode) = stub?.result {
            let response = HTTPURLResponse(
                url: url,
                statusCode: statusCode,
                httpVersion: nil,
                headerFields: nil
            )!
            
            return (data, response)
        }
        
        throw NSError(domain: "no stubbed behaviour", code: 0)
    }
}
