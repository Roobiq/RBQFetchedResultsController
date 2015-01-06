//
//  RBQSafeRealmObject.m
//  RBQFetchedResultsControllerTest
//
//  Created by Lauren Smith on 1/4/15.
//  Copyright (c) 2015 Roobiq. All rights reserved.
//

#import "RBQSafeRealmObject.h"
#import <Realm/RLMProperty_Private.h>
#import <objc/message.h>

@interface RBQSafeRealmObject ()

@property (strong, nonatomic) NSString *realmPath;

@end

@implementation RBQSafeRealmObject

+ (instancetype)safeObjectFromObject:(RLMObject *)object
{
    NSString *className = [[object class] performSelector:@selector(className)];
    
    id value = [RBQSafeRealmObject primaryKeyValueForObject:object];
    
    RLMProperty *primaryKeyProperty = object.objectSchema.primaryKeyProperty.copy;
    
    RBQSafeRealmObject *safeObject = [[RBQSafeRealmObject alloc] initWithClassName:className
                                                                   primaryKeyValue:value
                                                                primaryKeyProperty:primaryKeyProperty
                                                                             realm:object.realm];
    
    return safeObject;
}

+ (RLMObject *)objectfromSafeObject:(RBQSafeRealmObject *)safeObject
{
    return [RBQSafeRealmObject objectInRealm:[RLMRealm defaultRealm] fromSafeObject:safeObject];
}

+ (RLMObject *)objectInRealm:(RLMRealm *)realm
              fromSafeObject:(RBQSafeRealmObject *)safeObject
{
    return [NSClassFromString(safeObject.className) objectInRealm:realm forPrimaryKey:safeObject.primaryKeyValue];
}

+ (id)primaryKeyValueForObject:(RLMObject *)object
{
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

- (id)initWithClassName:(NSString *)className
        primaryKeyValue:(id)primaryKeyValue
     primaryKeyProperty:(RLMProperty *)primaryKeyProperty
                  realm:(RLMRealm *)realm
{
    self = [super init];
    
    if (self) {
        _className = className;
        _primaryKeyValue = primaryKeyValue;
        _primaryKeyProperty = primaryKeyProperty;
        _realmPath = realm.path;
    }
    
    return self;
}

#pragma mark - Getter

- (RLMRealm *)realm
{
    return [RLMRealm realmWithPath:self.realmPath];
}

- (RLMObject *)RLMObject
{
    return [RBQSafeRealmObject objectInRealm:[RLMRealm defaultRealm] fromSafeObject:self];
}

#pragma mark - Equality

- (BOOL)isEqualToObject:(RBQSafeRealmObject *)object
{
    // if identical object
    if (self == object) {
        return YES;
    }
    
    if (_primaryKeyProperty.type == RLMPropertyTypeString) {
        return [self.primaryKeyValue isEqualToString:object.primaryKeyValue];
    }
    
    return self.primaryKeyValue == object.primaryKeyValue;
}

- (BOOL)isEqual:(id)object
{
    if (_primaryKeyValue) {
        return [self isEqualToObject:object];
    }
    else {
        return [super isEqual:object];
    }
}

- (NSUInteger)hash
{
    if (_primaryKeyValue) {
        // modify the hash of our primary key value to avoid potential (although unlikely) collisions
        return [_primaryKeyValue hash] ^ 1;
    }
    else {
        return [super hash];
    }
}

#pragma mark - <NSCopying>

- (id)copyWithZone:(NSZone *)zone
{
    RBQSafeRealmObject *safeObject = [[RBQSafeRealmObject allocWithZone:zone] init];
    safeObject->_className = _className;
    safeObject->_primaryKeyValue = _primaryKeyValue;
    safeObject->_primaryKeyProperty = _primaryKeyProperty;
    safeObject->_realmPath = _realmPath;
    
    return safeObject;
}

@end
