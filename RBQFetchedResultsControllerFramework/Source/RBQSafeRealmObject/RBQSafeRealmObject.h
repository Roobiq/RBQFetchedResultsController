//
//  RBQSafeRealmObject.h
//  RealmUtilities
//
//  Created by Adam Fish on 1/4/15.
//  Copyright (c) 2015 Roobiq. All rights reserved.
//

#import <Realm/Realm.h>
#import <Realm/RLMProperty.h>

/**
 *  An RBQSafeRealmObject acts as a thread-safe representation of a RLMObject.
 *
 *  @warning RBQSafeRealmObjects can only be created from RLMObjects that contain a primary key.
 *  Attempting to create a RBQSafeRealmObject without a primary key will result in an exception.
 */
@interface RBQSafeRealmObject : NSObject <NSCopying>

/**
 *  Original RLMObject's class name
 */
@property (nonatomic, readonly, nonnull) NSString *className;

/**
 *  Original RLMObject's primary key value
 */
@property (nonatomic, readonly, nonnull) id primaryKeyValue;

/**
 *  Original RLMObject's primary key property
 */
@property (nonatomic, readonly) RLMPropertyType primaryKeyType;

/**
 *  The Realm in which this object is persisted. Generated on demand.
 */
@property (nonatomic, readonly, nonnull) RLMRealm *realm;

/**
 *  The configuration object used to create an instance of RLMRealm for the fetch request
 */
@property (nonatomic, readonly, nonnull) RLMRealmConfiguration *realmConfiguration;

/**
 *  Constructor method to create an instance of RBQSafeRealmObject
 *
 *  @param className       class name for the original RLMObject
 *  @param primaryKeyValue primary key value for the original RLMObject
 *  @param primaryKeyType  primary key type for the original RLMObject
 *  @param realm           Realm in which the original RLMObject is persisted
 *
 *  @return A new instance of RBQSafeRealmObject
 */
- (nonnull id)initWithClassName:(nonnull NSString *)className
        primaryKeyValue:(nonnull id)primaryKeyValue
         primaryKeyType:(RLMPropertyType)primaryKeyType
                  realm:(nonnull RLMRealm *)realm;

/**
 *  Create a RBQSafeObject from a RLMObject
 *
 *  @param object The RLMObject to transform into RBQSafeObject
 *
 *  @return RBQSafeObject which is a thread-safe
 */
+ (nonnull instancetype)safeObjectFromObject:(nonnull RLMObjectBase *)object;

/**
 *  Create a RLMObject from a RBQSafeObject
 *
 *  @param safeObject RBQSafeRealmObject instance
 *
 *  @return RLMObject (not thread-safe)
 */
+ (nonnull id)objectfromSafeObject:(nonnull RBQSafeRealmObject *)safeObject;

/**
 *  Quickly convert a RBQSafeRealmObject into its RLMObject
 *
 *  @return RLMObject
 */
- (nonnull id)RLMObject;

/**
 *  Equality test for RBQSafeRealmObject
 *
 *  @param object RBQSafeRealmObject to compare
 *
 *  @return YES if both objects contain the same primary key
 */
- (BOOL)isEqualToObject:(nonnull RBQSafeRealmObject *)object;

@end
