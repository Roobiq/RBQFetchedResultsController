//
//  RLMResults+Notifications.h
//  RBQFRCDynamicExample
//
//  Created by Adam Fish on 7/23/15.
//  Copyright (c) 2015 Adam Fish. All rights reserved.
//

#import <Realm/Realm.h>

/**
 *	Helper category for RLMResults that supports registering changes when performing bulk updates.
 */
@interface RLMResults (Notifications)

/**
 *	Bulk update values by invoking `setValue:forKey:` and registers a change
 *  on each of the array's items using the specified `value` and `key`.
 *
 *	@param value	The object value.
 *	@param key		The name of the property.
 */
- (void)setValueWithNotification:(id)value forKey:(NSString *)key;

@end
