//
//  RLMObject+Utilities.h
//  RealmUtilities 
//
//  Created by Adam Fish on 1/9/15.
//  Copyright (c) 2015 Roobiq. All rights reserved.
//

#import <Realm/Realm.h>
/**
 *  This utility category provides convenience methods to retrieve the primary key and original
 *  class name for an RLMObject.
 */
@interface RLMObject (Utilities)

/**
 *  Retrieve the primary key for a given RLMObject
 *
 *  @param object RLMObject with a primary key
 *
 *  @return Primary key value (NSInteger or NSString only)
 */
+ (nonnull id)primaryKeyValueForObject:(nonnull RLMObject *)object;

/**
 *  Checks to see if this object exist in the passed in RLMRealm by doing a primary key look up.
 *
 *  @param realm RLMRealm to checked for existance of the current object
 *
 *  @return BOOL value for if an object with the same primary key exists in realm or not.
 */
- (BOOL)isContainedInRealm:(nonnull RLMRealm *)realm;

@end
