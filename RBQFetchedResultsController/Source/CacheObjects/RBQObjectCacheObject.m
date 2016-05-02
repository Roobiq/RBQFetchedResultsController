//
//  RBQObjectCacheObject.m
//  RBQFetchedResultsControllerExample
//
//  Created by Adam Fish on 1/6/15.
//  Copyright (c) 2015 Roobiq. All rights reserved.
//

#import "RBQObjectCacheObject.h"
#import "RLMObjectBase+Utilities.h"

#import <Realm/RLMRealm_Dynamic.h>
#import <Realm/RLMObjectBase_Dynamic.h>
#import <Realm/RLMObjectSchema.h>

@implementation RBQObjectCacheObject

#pragma mark - Public Class

+ (instancetype)createCacheObjectWithObject:(RLMObjectBase *)object
                        sectionKeyPathValue:(NSString *)sectionValue
{
    RBQObjectCacheObject *cacheObject = [[RBQObjectCacheObject alloc] init];
    
    RLMObjectSchema *objectSchema = RLMObjectBaseObjectSchema(object);
    
    cacheObject.primaryKeyType = objectSchema.primaryKeyProperty.type;
    cacheObject.sectionKeyPathValue = sectionValue;
    cacheObject.className = [[object class] className];
    
    id primaryKeyValue = [RLMObjectBase primaryKeyValueForObject:object];
    
    if (cacheObject.primaryKeyType == RLMPropertyTypeString) {
        cacheObject.primaryKeyStringValue = (NSString *)primaryKeyValue;
    }
    else if (cacheObject.primaryKeyType == RLMPropertyTypeInt) {
        cacheObject.primaryKeyStringValue = ((NSNumber *)primaryKeyValue).stringValue;
    }
    else {
        @throw([self unsupportedPrimaryKeyTypeException]);
    }
    
    return cacheObject;
}

+ (instancetype)createCacheObjectWithSafeObject:(RBQSafeRealmObject *)safeObject
                            sectionKeyPathValue:(NSString *)sectionValue
{
    RBQObjectCacheObject *cacheObject = [[RBQObjectCacheObject alloc] init];
    cacheObject.primaryKeyType = safeObject.primaryKeyType;
    cacheObject.sectionKeyPathValue = sectionValue;
    cacheObject.className = safeObject.className;
    
    if (cacheObject.primaryKeyType == RLMPropertyTypeString) {
        cacheObject.primaryKeyStringValue = (NSString *)safeObject.primaryKeyValue;
    }
    else if (cacheObject.primaryKeyType == RLMPropertyTypeInt) {
        cacheObject.primaryKeyStringValue = ((NSNumber *)safeObject.primaryKeyValue).stringValue;
    }
    else {
        @throw([self unsupportedPrimaryKeyTypeException]);
    }
    
    return cacheObject;
}

+ (instancetype)cacheObjectInRealm:(RLMRealm *)realm
                         forObject:(RLMObjectBase *)object
{
    if (object) {
        id primaryKeyValue = [RLMObject primaryKeyValueForObject:object];
        
        RLMObjectSchema *objectSchema = RLMObjectBaseObjectSchema(object);
        
        RLMPropertyType primaryKeyType = objectSchema.primaryKeyProperty.type;
        
        if (primaryKeyType == RLMPropertyTypeString) {
            
            return [RBQObjectCacheObject objectInRealm:realm
                                         forPrimaryKey:primaryKeyValue];
        }
        else if (primaryKeyType == RLMPropertyTypeInt) {
            NSString *primaryKeyStringValue = ((NSNumber *)primaryKeyValue).stringValue;
            
            return [RBQObjectCacheObject objectInRealm:realm
                                         forPrimaryKey:primaryKeyStringValue];
        }
        else {
            @throw([self unsupportedPrimaryKeyTypeException]);
        }
    }
    
    return nil;
}

+ (RLMObject *)objectInRealm:(RLMRealm *)realm
              forCacheObject:(RBQObjectCacheObject *)cacheObject
{
    if (cacheObject.primaryKeyType == RLMPropertyTypeString) {
        
        return [realm objectWithClassName:cacheObject.className forPrimaryKey:cacheObject.primaryKeyStringValue];
    }
    else if (cacheObject.primaryKeyType == RLMPropertyTypeInt) {
        NSNumber *numberFromString = @(cacheObject.primaryKeyStringValue.longLongValue);
        
        return [realm objectWithClassName:cacheObject.className forPrimaryKey:numberFromString];
    }
    else {
        @throw ([self unsupportedPrimaryKeyTypeException]);
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

#pragma mark - Public Instance

- (id)primaryKeyValue
{
    if (self.primaryKeyType == RLMPropertyTypeInt) {
        NSNumber *numberFromString = @(self.primaryKeyStringValue.integerValue);
        
        return numberFromString;
    }
    
    return self.primaryKeyStringValue;
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
    return [self isEqualToObject:object];
}

#pragma mark - <NSCopying>

- (id)copyWithZone:(NSZone *)zone
{
    RBQObjectCacheObject *objectCache = [[RBQObjectCacheObject allocWithZone:zone] init];
    objectCache.className = _className;
    objectCache.primaryKeyStringValue = _primaryKeyStringValue;
    objectCache.primaryKeyType = _primaryKeyType;
    objectCache.sectionKeyPathValue = _sectionKeyPathValue;
    objectCache.section = _section;
    
    return objectCache;
}

#pragma mark - Helper exception

+ (NSException *)unsupportedPrimaryKeyTypeException
{
    return [NSException exceptionWithName:@"Unsupported primary key type"
                                   reason:@"RBQFetchedResultsController only supports NSString or int/NSInteger primary keys"
                                 userInfo:nil];
}

@end
