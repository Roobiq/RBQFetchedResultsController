//
//  RBQObjectCacheObject.h
//  RBQFetchedResultsControllerExample
//
//  Created by Adam Fish on 1/6/15.
//  Copyright (c) 2015 Roobiq. All rights reserved.
//

#import <Realm/Realm.h>
#import "RBQSafeRealmObject.h"
#import "RBQSectionCacheObject.h"

@class RBQSectionCacheObject;

/**
 * Internal object used by RBQFetchedResultsController.
 *
 * RBQObjectCacheObject represents the original RLMObject within the FRC cache.
 *
 *  @warning This class is not to be used external the RBQFetchedResultsController
 */
@interface RBQObjectCacheObject : RLMObject <NSCopying>

/**
 *  Original RLMObject class name
 */
@property NSString *className;

/**
 *  Primary key value represented as a string
 */
@property NSString *primaryKeyStringValue;

/**
 *  Primary key type (use to convert the string value if necessary)
 *
 * @warning Only supports RLMPropertyTypeInt and RLMPropertyTypeString, which are the only
 * supported Realm primary key types as of v0.90.5.
 */
@property NSInteger primaryKeyType;

/**
 *  Value for the section (i.e. the section name)
 */
@property NSString *sectionKeyPathValue;

/**
 *  Section for the cache object
 */
@property RBQSectionCacheObject *section;

/**
 *  Create RBQFetchedResultsCacheObject from RLMObject
 *
 *  @param object       RLMObject being represented in the cache
 *  @param sectionValue The section key path value for this object
 *
 *  @return A new instance of RBQFetchedResultsCacheObject
 */
+ (instancetype)createCacheObjectWithObject:(RLMObject *)object
                        sectionKeyPathValue:(NSString *)sectionValue;

/**
 *  Create RBQFetchedResultsCacheObject from RBQSafeObject
 *
 *  @param safeObject   RBQSafeRealmObject being represented in the cache
 *  @param sectionValue The section key path value for this object
 *
 *  @return A new instance of RBQFetchedResultsCacheObject
 */
+ (instancetype)createCacheObjectWithSafeObject:(RBQSafeRealmObject *)safeObject
                            sectionKeyPathValue:(NSString *)sectionValue;

/**
 *  Retrieve RBQFetchedResultsCacheObject from a Realm instance from RLMObject
 *
 *  @param realm  The RLMRealm in which the cache object is persisted
 *  @param object The RLMObject that is represented by the cache object
 *
 *  @return A instance of RBQFetchedResultsCacheObject
 */
+ (instancetype)cacheObjectInRealm:(RLMRealm *)realm
                         forObject:(RLMObject *)object;

/**
 *  Retrieve RLMObject in given Realm instance for RBQFetchedResultsCacheObject
 *
 *  @param realm       The RLMRealm in which the cache object is persisted
 *  @param cacheObject The RBQObjectCacheObject representing the RLMObject
 *
 *  @return A instance of RLMObject
 */
+ (RLMObject *)objectInRealm:(RLMRealm *)realm
              forCacheObject:(RBQObjectCacheObject *)cacheObject;

@end

// This protocol enables typed collections. i.e.:
// RLMArray<RBQObjectCacheObject>
