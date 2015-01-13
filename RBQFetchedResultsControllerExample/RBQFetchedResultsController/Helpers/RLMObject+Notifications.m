//
//  RLMObject+Notifications.m
//  RBQFetchedResultsControllerExample
//
//  Created by Adam Fish on 1/13/15.
//  Copyright (c) 2015 Roobiq. All rights reserved.
//

#import "RLMObject+Notifications.h"
#import "RBQRealmNotificationManager.h"

@implementation RLMObject (Notifications)

- (void)changeWithNotification:(RBQChangeNotificationBlock)block
{
    block(self);
    
    // Call Notification
    [[RBQRealmNotificationManager managerForRealm:self.realm] didChangeObject:self];
}

- (void)changeWithNotificationInTransaction:(RBQChangeNotificationBlock)block
{
    RLMRealm *realm = self.realm;
    
    [realm beginWriteTransaction];
    
    block(self);
    
    // Call Notification
    [[RBQRealmNotificationManager managerForRealm:realm] didChangeObject:self];
    
    [realm commitWriteTransaction];
}

@end
