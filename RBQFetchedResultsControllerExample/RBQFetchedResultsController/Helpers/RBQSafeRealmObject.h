//
//  RBQSafeRealmObject.h
//  RBQFetchedResultsControllerTest
//
//  Created by Lauren Smith on 1/4/15.
//  Copyright (c) 2015 Roobiq. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Realm/Realm.h>

@interface RBQSafeRealmObject : NSObject <NSCopying>

// Original RLMObject's class name
@property (strong, nonatomic, readonly) NSString *className;

// Original RLMObject's primary key value
@property (strong, nonatomic, readonly) id primaryKeyValue;

// Original RLMObject's primary key property
@property (strong, nonatomic, readonly) RLMProperty *primaryKeyProperty;

// The Realm in which this object is persisted
@property (nonatomic, readonly) RLMRealm *realm;

// Create a RBQSafeObject from a RLMObject
+ (instancetype)safeObjectFromObject:(RLMObject *)object;

// Create a RLMObject from a RBQSafeObject
+ (RLMObject *)objectfromSafeObject:(RBQSafeRealmObject *)safeObject;

// Create a RLMObject in a specific Realm from a RBQSafeObject
+ (RLMObject *)objectInRealm:(RLMRealm *)realm
              fromSafeObject:(RBQSafeRealmObject *)safeObject;

// Convert a RBQSafeObject to a RLMObject
- (RLMObject *)RLMObject;

// Equality test for RBQSafeObject
- (BOOL)isEqualToObject:(RBQSafeRealmObject *)object;

@end
