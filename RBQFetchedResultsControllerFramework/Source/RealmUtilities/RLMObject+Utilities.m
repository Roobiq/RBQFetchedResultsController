//
//  RLMObject+Utilities.m
//  RealmUtilities 
//
//  Created by Adam Fish on 1/9/15.
//  Copyright (c) 2015 Roobiq. All rights reserved.
//

#import "RLMObject+Utilities.h"

#import <Realm/Realm.h>
#import <Realm/RLMRealm_Dynamic.h>
#import <Realm/RLMObjectSchema.h>
#import <Realm/RLMProperty.h>

@implementation RLMObject (Utilities)

+ (id)primaryKeyValueForObject:(RLMObject *)object
{
    if (!object) {
        return nil;
    }
    
    RLMProperty *primaryKeyProperty = object.objectSchema.primaryKeyProperty;
    
    if (primaryKeyProperty) {
        id value = nil;
        
        value = [object valueForKey:primaryKeyProperty.name];
        
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
}

- (BOOL)isContainedInRealm:(RLMRealm *)realm
{
    if (!realm || !self.objectSchema.primaryKeyProperty) {
        return NO;
    }
    
    id primaryKeyValue = nil;
    primaryKeyValue = [RLMObject primaryKeyValueForObject:self];
    
    if (primaryKeyValue) {
        NSString *objectClassName = [[self class] className];
        
        return !![realm objectWithClassName:objectClassName forPrimaryKey:primaryKeyValue];
    } else {
        return NO;
    }
}

@end
