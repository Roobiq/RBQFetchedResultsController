//
//  RLMObjectBase+Utilities.h
//  RBQFRCSwiftExample
//
//  Created by Adam Fish on 7/30/15.
//  Copyright (c) 2015 Adam Fish. All rights reserved.
//

#import <Realm/Realm.h>

/**
 *  This utility category provides convenience methods to retrieve the primary key and original
 *  class name for an RLMObjectBase.
 */
@interface RLMObjectBase (Utilities)

/**
 *  Retrieve the primary key for a given RLMObjectBase
 *
 *  @param object RLMObjectBase with a primary key
 *
 *  @return Primary key value (NSInteger or NSString only)
 */
+ (nonnull id)primaryKeyValueForObject:(nonnull RLMObjectBase *)object;

@end
