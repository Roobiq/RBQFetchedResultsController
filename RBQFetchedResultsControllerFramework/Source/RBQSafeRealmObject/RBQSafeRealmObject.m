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
#import <Realm/RLMObjectBase_Dynamic.h>

static id RLMObjectBasePrimaryKeyValue(RLMObjectBase *object) {
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

@implementation RBQSafeRealmObject
@synthesize className = _className,
            primaryKeyType = _primaryKeyType,
            primaryKeyValue = _primaryKeyValue,
            realmConfiguration = _realmConfiguration;

+ (instancetype)safeObjectFromObject:(RLMObjectBase *)object
{
    if (!object || ![[object class] primaryKey]) {
        return nil;
    }
    
    NSString *className = [[object class] className];
    
    id value = RLMObjectBasePrimaryKeyValue(object);
    
    RLMObjectSchema *objectSchema = RLMObjectBaseObjectSchema(object);
    
    RLMProperty *primaryKeyProperty = objectSchema.primaryKeyProperty;
    
    RLMRealm *realm = RLMObjectBaseRealm(object);
    
    return [[self alloc] initWithClassName:className
                           primaryKeyValue:value
                            primaryKeyType:primaryKeyProperty.type
                                     realm:realm];
}

+ (id)objectfromSafeObject:(RBQSafeRealmObject *)safeObject
{
    return [safeObject.realm objectWithClassName:safeObject.className
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
        _realmConfiguration = realm.configuration;
    }
    
    return self;
}

#pragma mark - Getter

- (RLMRealm *)realm
{
    return [RLMRealm realmWithConfiguration:self.realmConfiguration
                                      error:nil];
}

- (id)RLMObject
{
    return [RBQSafeRealmObject objectfromSafeObject:self];
}

#pragma mark - Equality

- (BOOL)isEqualToObject:(RBQSafeRealmObject *)object
{
    // if identical object
    if (self == object) {
        return YES;
    }
    else if (self.primaryKeyType != object.primaryKeyType) {
        return NO;
    }
    else if (self.primaryKeyType == RLMPropertyTypeInt) {
        return [self.primaryKeyValue isEqual:object.primaryKeyValue];
    }
    else if (self.primaryKeyType == RLMPropertyTypeString) {
        NSString *lhsPrimaryKeyValue = (NSString *)self.primaryKeyValue;
        NSString *rhsPrimaryKeyValue = (NSString *)object.primaryKeyValue;
        
        return [lhsPrimaryKeyValue isEqualToString:rhsPrimaryKeyValue];
    }
    
    return NO;
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
    safeObject->_realmConfiguration = _realmConfiguration;
    
    return safeObject;
}

@end
