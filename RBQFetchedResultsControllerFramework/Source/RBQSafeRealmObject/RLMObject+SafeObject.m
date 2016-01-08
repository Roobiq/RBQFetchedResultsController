//
//  RLMObject+SafeObject.m
//  Roobiq
//
//  Created by Christopher Vermilion on 2/11/15.
//  Copyright (c) 2015 Roobiq. All rights reserved.
//

#import "RLMObject+SafeObject.h"
#import "RBQSafeRealmObject.h"

@implementation RLMObject (SafeObject)

- (RBQSafeRealmObject *)rbq_safeObject
{
    return [RBQSafeRealmObject safeObjectFromObject:self];
}

+ (instancetype)rbq_objectFromSafeObject:(RBQSafeRealmObject *)safeObject
{
    if (![[self className] isEqualToString:safeObject.className] || !safeObject.primaryKeyValue) {
        return nil;
    }
    return [self objectForPrimaryKey:safeObject.primaryKeyValue];
}

+ (instancetype)rbq_objectInRealm:(RLMRealm *)realm fromSafeObject:(RBQSafeRealmObject *)safeObject
{
    if (![[self className] isEqualToString:safeObject.className] || !safeObject.primaryKeyValue) {
        return nil;
    }
    return [self objectInRealm:realm forPrimaryKey:safeObject.primaryKeyValue];

}

@end
