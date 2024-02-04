//
//  CoreDataFeedStore.swift
//  EssentialFeed
//
//  Created by Sahil Behl on 2024-01-28.
//

import CoreData

public final class CoreDataFeedStore: FeedStore {
    private let container: NSPersistentContainer
    private let context: NSManagedObjectContext
    
    public init(storeURL: URL, bundle: Bundle = .main) throws {
        container = try NSPersistentContainer.load(modelName: "FeedStore", url: storeURL, in: bundle)
        context = container.newBackgroundContext()
    }
    
    public func insert(items: [LocalFeedImage], timeStamp: Date) async throws {
        try await context.perform {
            let managedCache = try ManagedCache.newUniqueInstance(in: self.context)
            managedCache.timeStamp = timeStamp
            managedCache.feed = ManagedFeedImage.images(from: items, in: self.context)
        }
        
        try self.context.save()
    }
    
    public func retrieve() async throws -> (Date?, [LocalFeedImage]) {
        let managedCache = try await context.perform {
            try ManagedCache.find(in: self.context)
        }
        
        guard let managedCache else {
            return (nil, [])
        }
                
        return (managedCache.timeStamp, managedCache.localFeed)
    }
    
    public func delete() async throws {
        try await context.perform {
            try ManagedCache.find(in: self.context).map(self.context.delete).map(self.context.save)
        }
    }
}

extension ManagedCache {
    internal static func find(in context: NSManagedObjectContext) throws -> ManagedCache? {
            let request = NSFetchRequest<ManagedCache>(entityName: entity().name!)
            request.returnsObjectsAsFaults = false
            return try context.fetch(request).first
        }

        internal static func newUniqueInstance(in context: NSManagedObjectContext) throws -> ManagedCache {
            try find(in: context).map(context.delete)
            return ManagedCache(context: context)
        }

        internal var localFeed: [LocalFeedImage] {
            return feed!.compactMap { ($0 as? ManagedFeedImage)?.local }
        }
}

extension ManagedFeedImage {
    internal static func images(from localFeed: [LocalFeedImage], in context: NSManagedObjectContext) -> NSOrderedSet {
        return NSOrderedSet(array: localFeed.map { local in
            let managed = ManagedFeedImage(context: context)
            managed.id = local.id
            managed.imageDescription = local.description
            managed.location = local.location
            managed.url = local.url
            return managed
        })
    }

    internal var local: LocalFeedImage {
        return LocalFeedImage(id: id!, description: imageDescription, location: location, url: url!)
    }
}
