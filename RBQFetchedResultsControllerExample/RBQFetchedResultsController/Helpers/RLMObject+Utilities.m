//
//  RLMObject+Utilities.m
//  RBQFetchedResultsControllerExample
//
//  Created by Adam Fish on 1/9/15.
//  Copyright (c) 2015 Roobiq. All rights reserved.
//

#import "RLMObject+Utilities.h"

#import <Realm/Realm.h>
#import <Realm/RLMProperty_Private.h>

@implementation RLMObject (Utilities)

+ (id)primaryKeyValueForObject:(RLMObject *)object
{
    if (!object) {
        return nil;
    }
    
    RLMProperty *primaryKeyProperty = object.objectSchema.primaryKeyProperty;
    
    if (primaryKeyProperty) {
        id value = nil;
        
        if ([object respondsToSelector:primaryKeyProperty.getterSel]) {
            value = [object valueForKey:primaryKeyProperty.getterName];
        }
        
        if (!value) {
            @throw [NSException exceptionWithName:@"RBQException"
                                           reason:@"Primary key is nil"
                                         userInfo:nil];
        }
        
        return value;
    }
    
    @throw [NSException exceptionWithName:@"RBQException"
                                   reason:@"Object does not have a primary key"
                                 userInfo:nil];
    
    return @"InvalidObject";
}

+ (NSString *)classNameForObject:(RLMObject *)object
{
    return [[object class] className];
}

@end
