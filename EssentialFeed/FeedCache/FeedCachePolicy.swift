//
//  File.swift
//  EssentialFeed
//
//  Created by Sahil Behl on 2023-12-03.
//

import Foundation

enum FeedCachePolicy {
    private static let calendar = Calendar(identifier: .gregorian)
    
    private static var maxCacheAgeInDays: Int {
        return 7
    }
    
    static func validate(_ timestamp: Date, against currentDate: Date) -> Bool {
        guard let maxCacheAge = calendar.date(byAdding: .day, value: maxCacheAgeInDays, to: timestamp) else {
            return false
        }
        return currentDate < maxCacheAge
    }
}
