//
//  RLMRealm+Notifications.m
//  RBQFetchedResultsControllerExample
//
//  Created by Adam Fish on 1/13/15.
//  Copyright (c) 2015 Roobiq. All rights reserved.
//

#import "RLMRealm+Notifications.h"
#import "RBQRealmNotificationManager.h"

@implementation RLMRealm (Notifications)

- (void)addObjectWithNotification:(RLMObject *)object
{
    [[RBQRealmNotificationManager managerForRealm:object.realm] didAddObject:object];
    
    [self addObject:object];
}

- (void)addObjectsWithNotification:(id<NSFastEnumeration>)array
{
    for (RLMObject *object in array) {
        if (![object isKindOfClass:[RLMObject class]]) {
            NSString *msg = [NSString stringWithFormat:@"Cannot insert objects of type %@ with addObjects:. Only RLMObjects are supported.", NSStringFromClass(object.class)];
            @throw [NSException exceptionWithName:@"RLMException" reason:msg userInfo:nil];
        }
        
        [[RBQRealmNotificationManager managerForRealm:object.realm] didAddObject:object];
        
        [self addObject:object];
    }
}

- (void)addOrUpdateObjectWithNotification:(RLMObject *)object
{
    NSString *className = NSStringFromClass(object.class);
    
    if ([className hasPrefix:@"RLMStandalone_"]) {
        [[RBQRealmNotificationManager managerForRealm:object.realm] didAddObject:object];
    }
    else {
        [[RBQRealmNotificationManager managerForRealm:object.realm] didChangeObject:object];
    }
    
    [self addOrUpdateObject:object];
}

- (void)addOrUpdateObjectsFromArrayWithNotification:(id)array
{
    for (RLMObject *object in array) {
        [self addOrUpdateObject:object];
    }
}

- (void)deleteObjectWithNotification:(RLMObject *)object
{
    [[RBQRealmNotificationManager managerForRealm:object.realm] willDeleteObject:object];
    
    [self deleteObject:object];
}

- (void)deleteObjectsWithNotification:(id)array
{
    for (RLMObject *object in array) {
        [[RBQRealmNotificationManager managerForRealm:object.realm] willDeleteObject:object];
    }
    
    [self deleteObjects:array];
}

@end
