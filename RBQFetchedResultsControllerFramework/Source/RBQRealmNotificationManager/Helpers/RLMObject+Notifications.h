//
//  RLMObject+Notifications.h
//  RBQFetchedResultsControllerExample
//
//  Created by Adam Fish on 1/13/15.
//  Copyright (c) 2015 Roobiq. All rights reserved.
//

#import <Realm/Realm.h>

/**
 Block used to edit a RLMObject while automatically notifying RBQRealmChangeLogger
 
 @param object Object to be edited (will need to be cast into appropriate subclass)
 */
NS_ASSUME_NONNULL_BEGIN
typedef void(^RBQChangeNotificationBlock)(id object);
NS_ASSUME_NONNULL_END

/**
 *  Category on RLMObject that provides convenience methods to change a RLMObject while automatically notifying RBQRealmChangeLogger
 */
@interface RLMObject (Notifications)

/**
 *  Convenience method that accepts a RBQChangeNotificationBlock, which contains the current RLMObject as a parameter. 
 *
 *  Edit the parameter object in the block and an automatic notification will be generated for RBQRealmChangeLogger
 *
 *  @param block Block contains the RLMObject used to call this method. Edit the RLMObject within the block.
 */
- (void)changeWithNotification:(nonnull RBQChangeNotificationBlock)block;

/**
 *  Convenience method that accepts a RBQChangeNotificationBlock, which contains the current RLMObject as a parameter.
 *
 *  The block will be run within the required beginWriteTransaction and commitWriteTransaction calls automatically. Edit the parameter object in the block and an automatic notification will be generated for RBQRealmChangeLogger.
 *
 *  @param block Block contains the RLMObject used to call this method. Edit the RLMObject within the block.
 */
- (void)changeWithNotificationInTransaction:(nonnull RBQChangeNotificationBlock)block;

@end
