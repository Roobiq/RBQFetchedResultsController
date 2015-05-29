//
//  RBQControllerCacheObject.h
//  RBQFetchedResultsControllerExample
//
//  Created by Adam Fish on 1/6/15.
//  Copyright (c) 2015 Roobiq. All rights reserved.
//

#import <Realm/Realm.h>
#import "RBQSectionCacheObject.h"

/**
 Represents the current state of the FRC cache
 */
typedef NS_ENUM(NSUInteger, RBQControllerCacheState){
    /**
     Cache is ready
     */
    RBQControllerCacheStateReady,
    /**
     Cache is processing (if the app is forced closed in this state, the cache will be rebuilt)
     */
    RBQControllerCacheStateProcessing
};

RLM_ARRAY_TYPE(RBQSectionCacheObject)

/**
 * Internal cache object used by RBQFetchedResultsController.
 *
 * @warning This class is not to be used external the RBQFetchedResultsController
 */
@interface RBQControllerCacheObject : RLMObject

/**
 *  Name for the cache
 */
@property NSString *name;

/**
 *  Hash for RBQFetchRequest to monitor if cache needs rebuilt
 */
@property NSInteger fetchRequestHash;

/**
 *  Used to track if the cache was processing while app is terminated
 *
 *  @warning If cache is not ready, when requested, it will be rebuilt (this can occur if the app is forced closed while the cache is processing.
 */
@property NSInteger state DEPRECATED_MSG_ATTRIBUTE("Do not use.");

/**
 *  Used to track the current section name key path if any for the cache
 */
@property NSString *sectionNameKeyPath;

/**
 *  RBQSectionCacheObjects within cache
 */
@property RLMArray<RBQSectionCacheObject> *sections;

/**
 *  All RBQFetchedResultsCacheObjects in cache
 */
@property RLMArray<RBQObjectCacheObject> *objects;

/**
 *  Create RBQFetchedResultsControllerCacheObject with a name and RBQFetchRequest hash (both used for identification)
 *
 *  @param name The name of the cache
 *  @param hash A RBQFetchRequest hash used to identify the cache
 *
 *  @return A new instance of RBQFetchedResultsControllerCacheObject
 */
+ (instancetype)cacheWithName:(NSString *)name
             fetchRequestHash:(NSInteger)hash;

@end

// This protocol enables typed collections. i.e.:
// RLMArray<RBQControllerCacheObject>
RLM_ARRAY_TYPE(RBQControllerCacheObject)
