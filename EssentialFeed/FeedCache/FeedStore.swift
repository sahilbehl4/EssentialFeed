//
//  FeedStore.swift
//  EssentialFeed
//
//  Created by Sahil Behl on 8/27/23.
//

import Foundation

public protocol FeedStore {
    func delete() async throws
    func insert(items: [FeedItem], timeStamp: Date) async throws
}
