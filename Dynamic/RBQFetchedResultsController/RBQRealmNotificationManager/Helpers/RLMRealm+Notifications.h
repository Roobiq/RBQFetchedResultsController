//
//  RLMRealm+Notifications.h
//  RBQFetchedResultsControllerExample
//
//  Created by Adam Fish on 1/13/15.
//  Copyright (c) 2015 Roobiq. All rights reserved.
//

#import <Realm/Realm.h>

/**
 *  Category on RLMRealm that provides convenience methods similar to RLMRealm class methods but include notifying RBQRealmNotificationManager
 */
@interface RLMRealm (Notifications)

/**
 *  Convenience method to add an object to the Realm and notify RBQRealmChangeLogger
 *
 *  @param object Standalone RLMObject to be persisted
 */
- (void)addObjectWithNotification:(RLMObject *)object;

/**
 *  Convenience method to add a collection of RLMObjects to the Realm and notify RBQRealmChangeLogger
 *
 *  @param array A collection object that conforms to NSFastEnumeration (e.g. NSArray, RLMArray, RLMResults)
 */
- (void)addObjectsWithNotification:(id<NSFastEnumeration>)array;

/**
 *  Convenience method to add or update a RLMObject to the Realm and notify RBQRealmChangeLogger
 *
 *  If the RLMObject is already persisted, then the new object will be used to update the persisted object.
 *
 *  @param object RLMObject to add or update in the Realm
 */
- (void)addOrUpdateObjectWithNotification:(RLMObject *)object;

/**
 *  Convenience method to add or update a collection of RLMObjects to the Realm and notify RBQRealmChangeLogger
 *
 *  If any RLMObject is already persisted, then the new object will be used to update the persisted object.
 *
 *  @param array A collection object that conforms to NSFastEnumeration (e.g. NSArray, RLMArray, RLMResults)
 */
- (void)addOrUpdateObjectsFromArrayWithNotification:(id<NSFastEnumeration>)array;

/**
 *  Convenience method to delete a RLMObject from the Realm and notify RBQRealmChangeLogger
 *
 *  @param object RLMObject to delete from the Realm
 */
- (void)deleteObjectWithNotification:(RLMObject *)object;

/**
 *  Convenience method to delete a collection of RLMObjects from the Realm and notify RBQRealmChangeLogger
 *
 *  @param array A collection object that conforms to NSFastEnumeration (e.g. NSArray, RLMArray, RLMResults)
 */
- (void)deleteObjectsWithNotification:(id<NSFastEnumeration>)array;

@end
