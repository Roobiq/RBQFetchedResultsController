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

// Use these methods to register changes
- (void)didAddObject:(RLMObject *)addedObject;

// Must be called before the object is deleted from Realm
- (void)willDeleteObject:(RLMObject *)deletedObject;

- (void)didChangeObject:(RLMObject *)changedObject;

- (void)didAddObjects:(NSArray *)addedObjects
    willDeleteObjects:(NSArray *)deletedObjects
     didChangeObjects:(NSArray *)changedObjects;

// Notifications
// Must hold a strong reference to the returned token
- (RBQNotificationToken *)addNotificationBlock:(RBQNotificationBlock)block;

- (void)removeNotification:(RBQNotificationToken *)token;

@end
