//
//  RemoteFeedLoader.swift
//  EssentialFeed
//
//  Created by Sahil Behl on 7/2/23.
//

import Foundation

final public class RemoteFeedLoader: FeedLoader {
    private let url: URL
    private let httpClient: HTTPClient

    public init(url: URL, httpClient: HTTPClient) {
        self.httpClient = httpClient
        self.url = url
    }

    public func load() async throws -> [FeedImage] {
        if let (data, response) = try? await httpClient.get(from: url) {
            if let feedItems = try? FeedItemsMapper.map(data, response) {
                return feedItems.toModels()
            } else {
                throw Error.invalidData
            }
        } else {
            throw Error.connectivity
        }
    }

    public enum Error: Swift.Error {
        case connectivity
        case invalidData
    }
}

private extension Array where Element == RemoteFeedItem {
    func toModels() -> [FeedImage] {
        return map {
            FeedImage(id: $0.id, description: $0.description, location: $0.location, imageURL: $0.image)
        }
    }
}


