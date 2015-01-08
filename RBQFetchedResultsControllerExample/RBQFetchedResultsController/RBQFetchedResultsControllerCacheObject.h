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

@property NSString *cacheName;

@property NSInteger fetchRequestHash;

@property RLMArray<RBQSectionCacheObject> *sections;

@property RLMArray<RBQFetchedResultsCacheObject> *objects;

+ (instancetype)cacheWithName:(NSString *)name
             fetchRequestHash:(NSInteger)hash;

@end

// This protocol enables typed collections. i.e.:
// RLMArray<RBQFetchedResultsControllerCacheObject>
RLM_ARRAY_TYPE(RBQFetchedResultsControllerCacheObject)
