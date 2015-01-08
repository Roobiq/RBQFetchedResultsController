//
//  RBQSectionCacheObject.m
//  RBQFetchedResultsControllerExample
//
//  Created by Adam Fish on 1/6/15.
//  Copyright (c) 2015 Roobiq. All rights reserved.
//

#import "RBQSectionCacheObject.h"

@implementation RBQSectionCacheObject

+ (instancetype)cacheWithName:(NSString *)name
{
    RBQSectionCacheObject *section = [[RBQSectionCacheObject alloc] init];
    section.name = name;
    
    return section;
}

+ (NSString *)primaryKey
{
    return @"name";
}

+ (NSDictionary *)defaultPropertyValues
{
    return @{@"firstObjectIndex" : @(NSIntegerMin),
             @"name" : @""
             };
}


@end
