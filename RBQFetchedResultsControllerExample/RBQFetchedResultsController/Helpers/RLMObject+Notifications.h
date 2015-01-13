//
//  RLMObject+Notifications.h
//  RBQFetchedResultsControllerExample
//
//  Created by Adam Fish on 1/13/15.
//  Copyright (c) 2015 Roobiq. All rights reserved.
//

#import "RLMObject.h"

typedef void(^RBQChangeNotificationBlock)(RLMObject *object);

@interface RLMObject (Notifications)

- (void)changeWithNotification:(RBQChangeNotificationBlock)block;

- (void)changeWithNotificationInTransaction:(RBQChangeNotificationBlock)block;

@end
