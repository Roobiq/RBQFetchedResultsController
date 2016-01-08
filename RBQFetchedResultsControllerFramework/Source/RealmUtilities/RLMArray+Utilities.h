//
//  RLMArray+Utilities.h
//  RBQFetchedResultsControllerExample
//
//  Created by AsanoYuki on 2015/05/29.
//  Copyright (c) 2015年 Roobiq. All rights reserved.
//

#import <Realm/RLMArray.h>

/**
 *  This utility category provides convenience methods on RLMArray.
 */
@interface RLMArray (Utilities)

/**
 *  Detect if RLMArray contains a given RLMObject
 *
 *  @param anObject RLMObject
 *
 *  @return YES if RLMArray contains given object
 */
- (BOOL)containsObject:(nonnull RLMObject *)anObject;

@end
