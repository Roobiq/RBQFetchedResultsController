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

@property (strong, nonatomic, readonly) NSString *className;
@property (strong, nonatomic, readonly) id primaryKeyValue;
@property (strong, nonatomic, readonly) RLMProperty *primaryKeyProperty;
@property (nonatomic, readonly) RLMRealm *realm;

+ (instancetype)safeObjectFromObject:(RLMObject *)object;

+ (RLMObject *)objectfromSafeObject:(RBQSafeRealmObject *)safeObject;

+ (RLMObject *)objectInRealm:(RLMRealm *)realm
              fromSafeObject:(RBQSafeRealmObject *)safeObject;

+ (id)primaryKeyValueForObject:(RLMObject *)object;

- (RLMObject *)RLMObject;

- (BOOL)isEqualToObject:(RBQSafeRealmObject *)object;

@end
