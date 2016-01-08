//
//  RLMResults+Notifications.m
//  RBQFRCDynamicExample
//
//  Created by Adam Fish on 7/23/15.
//  Copyright (c) 2015 Adam Fish. All rights reserved.
//

#import "RLMResults+Notifications.h"
#import "RBQRealmNotificationManager.h"

@implementation RLMResults (Notifications)

- (void)setValueWithNotification:(id)value forKey:(NSString *)key
{
    // Perform the changes
    [self setValue:value forKey:key];
    
    // Register Notifications
    [[RBQRealmChangeLogger loggerForRealm:self.realm] didChangeObjects:self];
}

@end
