//
//  RLMArray+Utilities.m
//  RBQFetchedResultsControllerExample
//
//  Created by AsanoYuki on 2015/05/29.
//  Copyright (c) 2015年 Roobiq. All rights reserved.
//

#import "RLMArray+Utilities.h"
#import <Realm/RLMObject.h>

@implementation RLMArray (Utilities)

- (BOOL)containsObject:(RLMObject *)anObject
{
    if ([self indexOfObject:anObject] != NSNotFound) {
        return YES;
    }
    return NO;
}

@end
