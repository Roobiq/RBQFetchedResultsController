//
//  RBQFetchedResultsCacheObject.m
//  RBQFetchedResultsControllerExample
//
//  Created by Adam Fish on 1/6/15.
//  Copyright (c) 2015 Roobiq. All rights reserved.
//

#import "RBQFetchedResultsCacheObject.h"
#import <Realm/RLMProperty_Private.h>

@implementation RBQFetchedResultsCacheObject

+ (instancetype)cacheObjectWithPrimaryKeyValue:(id)value
                                primaryKeyType:(NSInteger)type
                           sectionKeyPathValue:(NSString *)sectionValue
{
    RBQFetchedResultsCacheObject *cacheObject = [[RBQFetchedResultsCacheObject alloc] init];
    cacheObject.primaryKeyType = type;
    cacheObject.sectionKeyPathValue = sectionValue;
    
    if (type == RLMPropertyTypeString) {
        cacheObject.primaryKeyStringValue = (NSString *)value;
    }
    else {
        cacheObject.primaryKeyStringValue = @((NSInteger)value).stringValue;
    }
    
    return cacheObject;
}

+ (NSString *)primaryKey
{
    return @"primaryKeyStringValue";
}

+ (NSDictionary *)defaultPropertyValues
{
    return @{@"primaryKeyStringValue" : @"",
             @"primaryKeyType" : @(NSIntegerMin),
             @"sectionKeyPathValue" : @""
             };
}

@end
