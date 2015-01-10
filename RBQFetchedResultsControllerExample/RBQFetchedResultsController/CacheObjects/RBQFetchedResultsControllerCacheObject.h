//
//  RBQFetchedResultsControllerCacheObject.h
//  RBQFetchedResultsControllerExample
//
//  Created by Adam Fish on 1/6/15.
//  Copyright (c) 2015 Roobiq. All rights reserved.
//

#import <Realm/Realm.h>
#import "RBQSectionCacheObject.h"

RLM_ARRAY_TYPE(RBQSectionCacheObject)

@interface RBQFetchedResultsControllerCacheObject : RLMObject

// Name for the cache
@property NSString *cacheName;

// Hash for RBQFetchRequest to monitor if cache needs rebuilt
@property NSInteger fetchRequestHash;

// RBQSectionCacheObjects within cache
@property RLMArray<RBQSectionCacheObject> *sections;

// All RBQFetchedResultsCacheObjects in cache
@property RLMArray<RBQFetchedResultsCacheObject> *objects;

// Create RBQFetchedResultsControllerCacheObject with a name and RBQFetchRequest hash
+ (instancetype)cacheWithName:(NSString *)name
             fetchRequestHash:(NSInteger)hash;

@end

// This protocol enables typed collections. i.e.:
// RLMArray<RBQFetchedResultsControllerCacheObject>
RLM_ARRAY_TYPE(RBQFetchedResultsControllerCacheObject)
