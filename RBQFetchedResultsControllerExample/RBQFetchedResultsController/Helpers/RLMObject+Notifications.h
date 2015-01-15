//
//  RLMObject+Notifications.h
//  RBQFetchedResultsControllerExample
//
//  Created by Adam Fish on 1/13/15.
//  Copyright (c) 2015 Roobiq. All rights reserved.
//

#import "RLMObject.h"

typedef void(^RBQChangeNotificationBlock)(RLMObject *object);

/**
 *  Category on RLMObject that provides convenience methods to change a RLMObject while automatically notifying RBQRealmNotificationManager
 */
@interface RLMObject (Notifications)

/**
 *  Convenience method that accepts a RBQChangeNotificationBlock, which contains the current RLMObject as a parameter. 
 
    Edit the parameter object in the block and an automatic notification will be generated for RBQRealmNotificationManager
 *
 *  @param block Block contains the RLMObject used to call this method. Edit the RLMObject within the block.
 */
- (void)changeWithNotification:(RBQChangeNotificationBlock)block;

/**
 *  Convenience method that accepts a RBQChangeNotificationBlock, which contains the current RLMObject as a parameter.
 
    The block will be run within the required beginWriteTransaction and commitWriteTransaction calls automatically. Edit the parameter object in the block and an automatic notification will be generated for RBQRealmNotificationManager.
 *
 *  @param block Block contains the RLMObject used to call this method. Edit the RLMObject within the block.
 */
- (void)changeWithNotificationInTransaction:(RBQChangeNotificationBlock)block;

@end
