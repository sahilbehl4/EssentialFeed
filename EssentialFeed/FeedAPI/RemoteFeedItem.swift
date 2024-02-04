//
//  RemoteFeedItem.swift
//  EssentialFeed
//
//  Created by Sahil Behl on 2023-11-05.
//

import Foundation

struct RemoteFeedItem: Decodable {
    let id: UUID
    let description: String?
    let location: String?
    let image: URL
}
