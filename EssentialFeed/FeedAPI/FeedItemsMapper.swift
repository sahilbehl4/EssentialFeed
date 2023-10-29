//
//  FeedItemsMapper.swift
//  EssentialFeed
//
//  Created by Sahil Behl on 8/2/23.
//

import Foundation

final class FeedItemsMapper {
    private struct Item: Decodable {
        let id: UUID
        let description: String?
        let location: String?
        let image: String

        var feedItem: FeedItem {
            FeedItem(
                id: id,
                description: description,
                location: location,
                imageURL: URL(string: image)!
            )
        }
    }

    private struct Root: Decodable {
        let items: [Item]
    }

    private static let okStatus = 200

    static func map(_ data: Data, _ response: HTTPURLResponse) throws -> [FeedItem] {
        guard response.statusCode == okStatus else {
            throw RemoteFeedLoader.Error.invalidData
        }

        let rootItem = try JSONDecoder().decode(Root.self, from: data)
        return rootItem.items.map { $0.feedItem }
    }
}
