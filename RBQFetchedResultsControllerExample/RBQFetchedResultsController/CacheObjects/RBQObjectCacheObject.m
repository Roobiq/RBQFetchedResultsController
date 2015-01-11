//
//  RBQObjectCacheObject.m
//  RBQFetchedResultsControllerExample
//
//  Created by Adam Fish on 1/6/15.
//  Copyright (c) 2015 Roobiq. All rights reserved.
//

#import "RBQObjectCacheObject.h"
#import <Realm/RLMProperty_Private.h>
#import "RLMObject+Utilities.h"

@implementation RBQObjectCacheObject

#pragma mark - Public Class

+ (instancetype)createCacheObjectWithObject:(RLMObject *)object
                        sectionKeyPathValue:(NSString *)sectionValue
{
    RBQObjectCacheObject *cacheObject = [[RBQObjectCacheObject alloc] init];
    cacheObject.primaryKeyType = object.objectSchema.primaryKeyProperty.type;
    cacheObject.sectionKeyPathValue = sectionValue;
    cacheObject.className = [RLMObject classNameForObject:object];
    
    id primaryKeyValue = [RLMObject primaryKeyValueForObject:object];
    
    if (cacheObject.primaryKeyType == RLMPropertyTypeString) {
        cacheObject.primaryKeyStringValue = (NSString *)primaryKeyValue;
    }
    else {
        cacheObject.primaryKeyStringValue = @((NSInteger)primaryKeyValue).stringValue;
    }
    
    return cacheObject;
}

+ (instancetype)createCacheObjectWithSafeObject:(RBQSafeRealmObject *)safeObject
                            sectionKeyPathValue:(NSString *)sectionValue
{
    RBQObjectCacheObject *cacheObject = [[RBQObjectCacheObject alloc] init];
    cacheObject.primaryKeyType = safeObject.primaryKeyProperty.type;
    cacheObject.sectionKeyPathValue = sectionValue;
    cacheObject.className = safeObject.className;
    
    if (cacheObject.primaryKeyType == RLMPropertyTypeString) {
        cacheObject.primaryKeyStringValue = (NSString *)safeObject.primaryKeyValue;
    }
    else {
        cacheObject.primaryKeyStringValue = @((NSInteger)safeObject.primaryKeyValue).stringValue;
    }
    
    return cacheObject;
}

+ (instancetype)cacheObjectInRealm:(RLMRealm *)realm
                         forObject:(RLMObject *)object
{
    if (object) {
        NSString *primaryKeyValue = (NSString *)[RLMObject primaryKeyValueForObject:object];
        
        if (object.objectSchema.primaryKeyProperty.type == RLMPropertyTypeString) {
            
            return [RBQObjectCacheObject objectInRealm:realm
                                         forPrimaryKey:primaryKeyValue];
        }
        else {
            NSNumber *numberFromString = @(primaryKeyValue.integerValue);
            
            return [RBQObjectCacheObject objectInRealm:realm
                                         forPrimaryKey:(id)numberFromString];
        }
    }
    
    return nil;
}

+ (RLMObject *)objectInRealm:(RLMRealm *)realm
              forCacheObject:(RBQObjectCacheObject *)cacheObject
{
    if (cacheObject.primaryKeyType == RLMPropertyTypeString) {
        
        return [NSClassFromString(cacheObject.className) objectInRealm:realm
                                                         forPrimaryKey:cacheObject.primaryKeyStringValue];
    }
    else {
        NSNumber *numberFromString = @(cacheObject.primaryKeyStringValue.integerValue);
        
        return [NSClassFromString(cacheObject.className) objectInRealm:realm
                                                         forPrimaryKey:(id)numberFromString];
    }
}

#pragma mark - RLMObject Class

+ (NSString *)primaryKey
{
    return @"primaryKeyStringValue";
}

+ (NSDictionary *)defaultPropertyValues
{
    return @{@"className": @"",
             @"primaryKeyStringValue" : @"",
             @"primaryKeyType" : @(NSIntegerMin),
             @"sectionKeyPathValue" : @""
             };
}

#pragma mark - Equality

- (BOOL)isEqualToObject:(RBQObjectCacheObject *)object
{
    if (self.primaryKeyType == RLMPropertyTypeString &&
        object.primaryKeyType == RLMPropertyTypeString) {
        
        return [self.primaryKeyStringValue isEqualToString:object.primaryKeyStringValue];
    }
    else if (self.primaryKeyType == RLMPropertyTypeInt &&
             object.primaryKeyType == RLMPropertyTypeInt) {
        
        return self.primaryKeyStringValue.integerValue == object.primaryKeyStringValue.integerValue;
    }
    else {
        return [super isEqual:object];
    }
}

- (BOOL)isEqual:(id)object
{
    NSString *className = NSStringFromClass(self.class);
    
    if ([className hasPrefix:@"RLMStandalone_"]) {
        return [self isEqualToObject:object];
    }
    else {
        return [super isEqual:object];
    }
}

#pragma mark - <NSCopying>

- (id)copyWithZone:(NSZone *)zone
{
    RBQObjectCacheObject *objectCache = [[RBQObjectCacheObject allocWithZone:zone] init];
    objectCache.className = self.className;
    objectCache.primaryKeyStringValue = self.primaryKeyStringValue;
    objectCache.primaryKeyType = self.primaryKeyType;
    objectCache.sectionKeyPathValue = self.sectionKeyPathValue;
    objectCache.section = self.section;
    
    return objectCache;
}

@end
