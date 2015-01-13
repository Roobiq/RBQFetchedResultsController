//
//  RLMRealm+Notifications.h
//  RBQFetchedResultsControllerExample
//
//  Created by Adam Fish on 1/13/15.
//  Copyright (c) 2015 Roobiq. All rights reserved.
//

#import "RLMRealm.h"

@interface RLMRealm (Notifications)

- (void)addObjectWithNotification:(RLMObject *)object;

- (void)addObjectsWithNotification:(id<NSFastEnumeration>)array;

- (void)addOrUpdateObjectWithNotification:(RLMObject *)object;

- (void)addOrUpdateObjectsFromArrayWithNotification:(id)array;

- (void)deleteObjectWithNotification:(RLMObject *)object;

- (void)deleteObjectsWithNotification:(id)array;

@end
