//
//  RBQRealmNotificationManager.h
//  RBQFetchedResultsControllerTest
//
//  Created by Lauren Smith on 1/4/15.
//  Copyright (c) 2015 Roobiq. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Realm/Realm.h>

#pragma mark - Constants

/*
    Block returns an array of:
        -RBQSafeRealmObjects representing added objects
        -RBQSafeRealmObjects representing deleted objects
        -RBQSafeRealmObjects representing changed objects
 */
typedef void(^RBQNotificationBlock)(NSArray *addedSafeObjects,
                                    NSArray *deletedSafeObjects,
                                    NSArray *changedSafeObjects,
                                    RLMRealm *realm);

@interface RBQNotificationToken : NSObject

@end

@interface RBQRealmNotificationManager : NSObject

// Utilizing the defaultRealm
+ (instancetype)defaultManager;

// Create a manager for a different Realm
+ (instancetype)managerForRealm:(RLMRealm *)realm;

// Create a manager for an in-memory Realm
+ (instancetype)managerForInMemoryRealm:(RLMRealm *)inMemoryRealm;

// ---------------------------
// Methods to register changes
// ---------------------------

// Register an add for a given RLMObject
// NOTE: Can be called before or after change to Realm
- (void)didAddObject:(RLMObject *)addedObject;

// Register a delete for a given RLMObject
// NOTE: MUST BE CALLED BEFORE DELETE IN REALM
- (void)willDeleteObject:(RLMObject *)deletedObject;

// Register a change for a given RLMObject
// NOTE: Can be called before or after change to Realm
- (void)didChangeObject:(RLMObject *)changedObject;

// Convenience method to pass array of objects changed
// Will ignore nil NSArray values
- (void)didAddObjects:(id<NSFastEnumeration>)addedObjects
    willDeleteObjects:(id<NSFastEnumeration>)deletedObjects
     didChangeObjects:(id<NSFastEnumeration>)changedObjects;

// Notifications
// Must hold a strong reference to the returned token
- (RBQNotificationToken *)addNotificationBlock:(RBQNotificationBlock)block;

// De-register a notification given a RBQNotificationToken
- (void)removeNotification:(RBQNotificationToken *)token;

@end
