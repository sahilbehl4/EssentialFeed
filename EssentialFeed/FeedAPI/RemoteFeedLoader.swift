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

    public func load(completion: @escaping ((Result<[FeedItem], Swift.Error>) -> Void)) {
        httpClient.get(from: url, completion: { [weak self] result in
            guard self != nil else { return }
            switch result {
            case .failure:
                completion(.failure(Error.connectivity))
            case .success(let (response, data)):
                if let feedItems = try? FeedItemsMapper.map(data, response) {
                    completion(.success(feedItems))
                } else {
                    completion(.failure(Error.invalidData))
                }
            }
        })
    }

    public enum Error: Swift.Error {
        case connectivity
        case invalidData
    }
}


