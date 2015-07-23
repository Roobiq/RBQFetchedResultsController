//
//  RBQSafeRealmObject.m
//  RealmUtilities
//
//  Created by Adam Fish on 1/4/15.
//  Copyright (c) 2015 Roobiq. All rights reserved.
//

#import "RBQSafeRealmObject.h"
#import "RLMObject+Utilities.h"

#import <Realm/RLMObjectSchema.h>
#import <Realm/RLMRealm_Dynamic.h>

@interface RBQSafeRealmObject ()

@property (strong, nonatomic) NSString *realmPath;

@end

@implementation RBQSafeRealmObject
@synthesize className = _className,
            primaryKeyType = _primaryKeyType,
            primaryKeyValue = _primaryKeyValue;

+ (instancetype)safeObjectFromObject:(RLMObject *)object
{
    if (!object || ![[object class] primaryKey]) {
        return nil;
    }
    
    NSString *className = [[object class] className];
    
    id value = [RLMObject primaryKeyValueForObject:object];
    
    RLMProperty *primaryKeyProperty = object.objectSchema.primaryKeyProperty;
    
    return [[self alloc] initWithClassName:className
                           primaryKeyValue:value
                            primaryKeyType:primaryKeyProperty.type
                                     realm:object.realm];
}

+ (id)objectfromSafeObject:(RBQSafeRealmObject *)safeObject
{
    return [RBQSafeRealmObject objectInRealm:[RLMRealm defaultRealm] fromSafeObject:safeObject];
}

+ (id)objectInRealm:(RLMRealm *)realm
     fromSafeObject:(RBQSafeRealmObject *)safeObject
{
    return [realm objectWithClassName:safeObject.className
                        forPrimaryKey:safeObject.primaryKeyValue];
}

- (id)initWithClassName:(NSString *)className
        primaryKeyValue:(id)primaryKeyValue
         primaryKeyType:(RLMPropertyType)primaryKeyType
                  realm:(RLMRealm *)realm
{
    self = [super init];
    
    if (self) {
        _className = className;
        _primaryKeyValue = primaryKeyValue;
        _primaryKeyType = primaryKeyType;
        _realmPath = realm.path;
    }
    
    return self;
}

#pragma mark - Getter

- (RLMRealm *)realm
{
    return [RLMRealm realmWithPath:self.realmPath];
}

- (id)RLMObject
{
    return [RBQSafeRealmObject objectInRealm:self.realm fromSafeObject:self];
}

#pragma mark - Equality

- (BOOL)isEqualToObject:(RBQSafeRealmObject *)object
{
    // if identical object
    if (self == object) {
        return YES;
    }
    
    return [self.primaryKeyValue isEqual:object.primaryKeyValue];
}

- (BOOL)isEqual:(id)object
{
    if (self == object) {
        return YES;
    }
    if (![object isKindOfClass:[RBQSafeRealmObject class]]) {
        return NO;
    }
    return [self isEqualToObject:object];
}

- (NSUInteger)hash
{
    return [_primaryKeyValue hash];
}

#pragma mark - <NSCopying>

- (id)copyWithZone:(NSZone *)zone
{
    RBQSafeRealmObject *safeObject = [[RBQSafeRealmObject allocWithZone:zone] init];
    safeObject->_className = _className;
    safeObject->_primaryKeyValue = _primaryKeyValue;
    safeObject->_primaryKeyType = _primaryKeyType;
    safeObject->_realmPath = _realmPath;
    
    return safeObject;
}

@end
