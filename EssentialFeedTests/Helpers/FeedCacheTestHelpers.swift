//
//  FeedCacheTestHelpers.swift
//  EssentialFeedTests
//
//  Created by Sahil Behl on 2023-12-03.
//

import EssentialFeed

func uniqueImageFeed() -> (models: [FeedImage], local: [LocalFeedImage]) {
    let models = [uniqueImage(), uniqueImage()]
    let local = models.map { LocalFeedImage(id: $0.id, description: $0.description, location: $0.location, url: $0.imageURL) }
    return (models, local)
}

func uniqueImage() -> FeedImage {
    return FeedImage(id: UUID(), description: "any", location: "any", imageURL: anyURL())
}

func anyURL() -> URL {
    return URL(string: "http://any-url.com")!
}

extension Date {
    func adding(days: Int) -> Date {
        return Calendar(identifier: .gregorian).date(byAdding: .day, value: days, to: self)!
    }
    
    func adding(seconds: TimeInterval) -> Date {
        return self + seconds
    }
    
    func minusFeedCacheMaxAge() -> Date {
        return adding(days: -feedCacheMaxAgeInDays)
    }
    
    private var feedCacheMaxAgeInDays: Int {
        return 7
    }
}
