//
//  RLMObject+Utilities.h
//  RBQFetchedResultsControllerExample
//
//  Created by Adam Fish on 1/9/15.
//  Copyright (c) 2015 Roobiq. All rights reserved.
//

#import "RLMObject.h"
/**
 *  This utility category provides convenience methods to retrieve the primary key and original class name for an RLMObject.
 */
@interface RLMObject (Utilities)

/**
 *  Retrieve the primary key for a given RLMObject
 *
 *  @param object RLMObject with a primary key
 *
 *  @return Primary key value (NSInteger or NSString only)
 */
+ (id)primaryKeyValueForObject:(RLMObject *)object;

/**
 *  Retrieve the original class name for a generic RLMObject. Realm dynamically changes the class at run-time, whereas this method returns the class name specified in the source code.
 *
 *  @param object A RLMObject
 *
 *  @return Original class name
 */
+ (NSString *)classNameForObject:(RLMObject *)object;

@end
