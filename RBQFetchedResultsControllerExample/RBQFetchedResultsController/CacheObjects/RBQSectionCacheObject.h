//
//  RBQSectionCacheObject.h
//  RBQFetchedResultsControllerExample
//
//  Created by Adam Fish on 1/6/15.
//  Copyright (c) 2015 Roobiq. All rights reserved.
//

#import <Realm/Realm.h>
#import "RBQObjectCacheObject.h"

RLM_ARRAY_TYPE(RBQObjectCacheObject)

@interface RBQSectionCacheObject : RLMObject

// Section name
@property NSString *name;

// Index of the first object contained within the section
@property NSInteger firstObjectIndex;

// Index of the first object contained within the section
@property NSInteger lastObjectIndex;

// Sorted RBQFetchedResultsCacheObjects in section
@property RLMArray<RBQObjectCacheObject> *objects;

// Create RBQSectionCacheObject with a given section name
+ (instancetype)cacheWithName:(NSString *)name;

@end

// This protocol enables typed collections. i.e.:
// RLMArray<RBQSectionCacheObject>