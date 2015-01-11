//
//  RBQControllerCacheObject.h
//  RBQFetchedResultsControllerExample
//
//  Created by Adam Fish on 1/6/15.
//  Copyright (c) 2015 Roobiq. All rights reserved.
//

#import <Realm/Realm.h>
#import "RBQSectionCacheObject.h"

typedef NS_ENUM(NSUInteger, RBQControllerCacheState) {
    RBQControllerCacheStateReady,
    RBQControllerCacheStateProcessing
};

RLM_ARRAY_TYPE(RBQSectionCacheObject)

@interface RBQControllerCacheObject : RLMObject

// Name for the cache
@property NSString *name;

// Hash for RBQFetchRequest to monitor if cache needs rebuilt
@property NSInteger fetchRequestHash;

// Used to track if the cache was processing while app is terminated
// If cache is not ready, when requested, it will be rebuilt
@property NSInteger state;

// RBQSectionCacheObjects within cache
@property RLMArray<RBQSectionCacheObject> *sections;

// All RBQFetchedResultsCacheObjects in cache
@property RLMArray<RBQObjectCacheObject> *objects;

// Create RBQFetchedResultsControllerCacheObject with a name and RBQFetchRequest hash
+ (instancetype)cacheWithName:(NSString *)name
             fetchRequestHash:(NSInteger)hash;

@end

// This protocol enables typed collections. i.e.:
// RLMArray<RBQControllerCacheObject>
RLM_ARRAY_TYPE(RBQControllerCacheObject)
