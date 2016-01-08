//
//  RLMObjectBase+Utilities.m
//  RBQFRCSwiftExample
//
//  Created by Adam Fish on 7/30/15.
//  Copyright (c) 2015 Adam Fish. All rights reserved.
//

#import "RLMObjectBase+Utilities.h"

#import <Realm/Realm.h>
#import <Realm/RLMObjectSchema.h>
#import <Realm/RLMProperty.h>
#import <Realm/RLMObjectBase_Dynamic.h>

@implementation RLMObjectBase (Utilities)

+ (id)primaryKeyValueForObject:(RLMObjectBase *)object
{
    if (!object) {
        return nil;
    }
    
    RLMObjectSchema *objectSchema = RLMObjectBaseObjectSchema(object);
    
    RLMProperty *primaryKeyProperty = objectSchema.primaryKeyProperty;
    
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

@end
