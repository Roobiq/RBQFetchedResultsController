//
//  RBQSectionCacheObject.h
//  RBQFetchedResultsControllerExample
//
//  Created by Adam Fish on 1/6/15.
//  Copyright (c) 2015 Roobiq. All rights reserved.
//

#import <Realm/Realm.h>
#import "RBQFetchedResultsCacheObject.h"

RLM_ARRAY_TYPE(RBQFetchedResultsCacheObject)

@interface RBQSectionCacheObject : RLMObject

@property NSString *name;

@property NSInteger firstObjectIndex;

@property RLMArray<RBQFetchedResultsCacheObject> *objects;

+ (instancetype)cacheWithName:(NSString *)name;

@end

// This protocol enables typed collections. i.e.:
// RLMArray<RBQSectionCacheObject>