//
//  FeedItemsMapper.swift
//  EssentialFeed
//
//  Created by Sahil Behl on 8/2/23.
//

import Foundation

final class FeedItemsMapper {
    private struct Root: Decodable {
        let items: [RemoteFeedItem]
    }

    private static let okStatus = 200

    static func map(_ data: Data, _ response: HTTPURLResponse) throws -> [RemoteFeedItem] {
        guard response.statusCode == okStatus else {
            throw RemoteFeedLoader.Error.invalidData
        }

        let rootItem = try JSONDecoder().decode(Root.self, from: data)
        return rootItem.items
    }
}
