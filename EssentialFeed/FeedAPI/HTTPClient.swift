//
//  HTTPClient.swift
//  EssentialFeed
//
//  Created by Sahil Behl on 8/2/23.
//

import Foundation

public protocol HTTPClient {
    func get(from url: URL) async throws -> (Data, HTTPURLResponse)
}

public final class URLSessionHTTPClient: HTTPClient {
    private let urlSession: URLSession

    public init(urlSession: URLSession = .shared) {
        self.urlSession = urlSession
    }

    public func get(from url: URL) async throws -> (Data, HTTPURLResponse) {
        return try await withCheckedThrowingContinuation { continuation in
            urlSession.dataTask(with: url) { data, response, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let data = data, let httpResponse = response as? HTTPURLResponse {
                    continuation.resume(returning: (data, httpResponse))
                } else {
                    continuation.resume(throwing: NSError(domain: "unexpected", code: 0))
                }
            }.resume()
        }
    }
}
