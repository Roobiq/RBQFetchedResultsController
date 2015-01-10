//
//  RBQFetchedResultsCacheObject.h
//  RBQFetchedResultsControllerExample
//
//  Created by Adam Fish on 1/6/15.
//  Copyright (c) 2015 Roobiq. All rights reserved.
//

#import <Realm/Realm.h>
#import "RBQSafeRealmObject.h"
#import "RBQSectionCacheObject.h"

@class RBQSectionCacheObject;

@interface RBQFetchedResultsCacheObject : RLMObject

// Original RLMObject class name
@property NSString *className;

// Primary key value represented as a string
@property NSString *primaryKeyStringValue;

// Primary key type (to convet value if necessary)
@property NSInteger primaryKeyType;

// Value for the section (i.e. the section name)
@property NSString *sectionKeyPathValue;

// Section for the cache object
@property RBQSectionCacheObject *section;

// Create RBQFetchedResultsCacheObject from RLMObject
+ (instancetype)createCacheObjectWithObject:(RLMObject *)object
                  sectionKeyPathValue:(NSString *)sectionValue;

// Create RBQFetchedResultsCacheObject from RBQSafeObject
+ (instancetype)createCacheObjectWithSafeObject:(RBQSafeRealmObject *)safeObject
                      sectionKeyPathValue:(NSString *)sectionValue;

// Retrieve RBQFetchedResultsCacheObject from a Realm instance from RLMObject
+ (instancetype)cacheObjectInRealm:(RLMRealm *)realm
                         forObject:(RLMObject *)object;

// Retrieve RLMObject in given Realm instance for RBQFetchedResultsCacheObject
+ (RLMObject *)objectForCacheObject:(RBQFetchedResultsCacheObject *)cacheObject
                            inRealm:(RLMRealm *)realm;

@end

// This protocol enables typed collections. i.e.:
// RLMArray<RBQFetchedResultsCacheObject>
