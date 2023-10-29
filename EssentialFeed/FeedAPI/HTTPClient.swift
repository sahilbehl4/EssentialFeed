//
//  HTTPClient.swift
//  EssentialFeed
//
//  Created by Sahil Behl on 8/2/23.
//

import Foundation

public protocol HTTPClient {
    func get(from url: URL, completion: @escaping ((Result<(HTTPURLResponse, Data), Error>) -> Void))
}

public final class URLSessionHTTPClient: HTTPClient {
    private let urlSession: URLSession

    public init(urlSession: URLSession = .shared) {
        self.urlSession = urlSession
    }

    public func get(from url: URL, completion: @escaping ((Result<(HTTPURLResponse, Data), Error>) -> Void)) {
        urlSession.dataTask(with: url) { data, response, error in
            if let error {
                completion(.failure(error))
            } else if let data = data, let httpResponse = response as? HTTPURLResponse {
                completion(.success((httpResponse, data)))
            } else {
                completion(.failure(NSError(domain: "unexpected", code: 0)))
            }
        }.resume()
    }
}
