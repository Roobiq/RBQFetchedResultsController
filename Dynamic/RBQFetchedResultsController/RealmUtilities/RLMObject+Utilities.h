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
+ (id)primaryKeyValueForObject:(RLMObjectBase *)object;

@end
