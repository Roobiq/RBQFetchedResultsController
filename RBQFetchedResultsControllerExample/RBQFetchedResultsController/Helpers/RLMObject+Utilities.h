//
//  RLMObject+Utilities.h
//  RBQFetchedResultsControllerExample
//
//  Created by Adam Fish on 1/9/15.
//  Copyright (c) 2015 Roobiq. All rights reserved.
//

#import "RLMObject.h"

@interface RLMObject (Utilities)

// Retrieve the primary key for a given object
+ (id)primaryKeyValueForObject:(RLMObject *)object;

// Retrieve the original class name for a generic RLMObject
+ (NSString *)classNameForObject:(RLMObject *)object;

@end
