//
//  RBQFetchedResultsControllerCacheObject.m
//  RBQFetchedResultsControllerExample
//
//  Created by Adam Fish on 1/6/15.
//  Copyright (c) 2015 Roobiq. All rights reserved.
//

#import "RBQFetchedResultsControllerCacheObject.h"

@implementation RBQFetchedResultsControllerCacheObject

+ (instancetype)cacheWithName:(NSString *)name
             fetchRequestHash:(NSInteger)hash
{
    RBQFetchedResultsControllerCacheObject *cache = [[RBQFetchedResultsControllerCacheObject alloc] init];
    cache.cacheName = name;
    cache.fetchRequestHash = hash;
    
    return cache;
}

+ (NSString *)primaryKey
{
    return @"cacheName";
}

@end
