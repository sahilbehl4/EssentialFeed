//
//  FeedLoader.swift
//  EssentialFeed
//
//  Created by Sahil Behl on 6/21/23.
//

import Foundation

protocol FeedLoader {
    func load() async throws -> [FeedImage]
}

