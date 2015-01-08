//
//  RBQFetchedResultsCacheObject.h
//  RBQFetchedResultsControllerExample
//
//  Created by Adam Fish on 1/6/15.
//  Copyright (c) 2015 Roobiq. All rights reserved.
//

#import <Realm/Realm.h>
#import "RBQSectionCacheObject.h"

@class RBQSectionCacheObject;

@interface RBQFetchedResultsCacheObject : RLMObject

@property NSString *primaryKeyStringValue;

@property NSInteger primaryKeyType;

@property NSString *sectionKeyPathValue;

@property RBQSectionCacheObject *section;

+ (instancetype)cacheObjectWithPrimaryKeyValue:(id)value
                                primaryKeyType:(NSInteger)type
                           sectionKeyPathValue:(NSString *)sectionValue;

@end

// This protocol enables typed collections. i.e.:
// RLMArray<RBQFetchedResultsCacheObject>
