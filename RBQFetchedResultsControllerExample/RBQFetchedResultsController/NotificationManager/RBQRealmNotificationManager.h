//
//  RBQRealmNotificationManager.h
//  RBQFetchedResultsControllerTest
//
//  Created by Lauren Smith on 1/4/15.
//  Copyright (c) 2015 Roobiq. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Realm/Realm.h>

#pragma mark - RBQClassChangesObject

@interface RBQEntityChangesObject : NSObject

@property (readonly, nonatomic) NSString *className;
@property (readonly, nonatomic) NSArray *addedSafeObjects;
@property (readonly, nonatomic) NSArray *deletedSafeObjects;
@property (readonly, nonatomic) NSArray *changedSafeObjects;

@end

#pragma mark - Constants

/**
 *  When added to a RBQRealmNotificationManager, this block fires when the tracked Realm changes.
 *
 *  @param entityChanges NSDictionary with the keys represented as the class name of an entity that had changes. The object in the dictionary is a RBQEntityChangesObject, which contains the specific changes.
 *  @param realm         RLMRealm that updated (this is the original RLMRealm instance that was acted on to perform the changes. Not thread-safe).
 */
typedef void(^RBQNotificationBlock)(NSDictionary *entityChanges,
                                    RLMRealm *realm);

@interface RBQNotificationToken : NSObject

@end

@interface RBQRealmNotificationManager : NSObject

/**
 *  Current representation of changes logged to the RBQRealmNotificationManager instance.
 */
@property (readonly, nonatomic) NSDictionary *entityChanges;

// Utilizing the defaultRealm
+ (instancetype)defaultManager;

// Create a manager for a different Realm
+ (instancetype)managerForRealm:(RLMRealm *)realm;

// Create a manager for an in-memory Realm
+ (instancetype)managerForInMemoryRealm:(RLMRealm *)inMemoryRealm;

// ---------------------------
// Methods to register changes
// ---------------------------

// Register an insert for a given RLMObject
// NOTE: Can be called before or after change to Realm
- (void)didAddObject:(RLMObject *)addedObject;

// Register inserts for a given RLMObject
// NOTE: Can be called before or after change to Realm
- (void)didAddObjects:(id<NSFastEnumeration>)addedObjects;

// Register a delete for a given RLMObject
// NOTE: MUST BE CALLED BEFORE DELETE IN REALM
- (void)willDeleteObject:(RLMObject *)deletedObject;

// Register deletes for a given RLMObject
// NOTE: MUST BE CALLED BEFORE DELETE IN REALM
- (void)willDeleteObjects:(id<NSFastEnumeration>)deletedObjects;

// Register a change for a given RLMObject
// NOTE: Can be called before or after change to Realm
- (void)didChangeObject:(RLMObject *)changedObject;

// Register changes for a given RLMObject
// NOTE: Can be called before or after change to Realm
- (void)didChangeObjects:(id<NSFastEnumeration>)changedObjects;

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
