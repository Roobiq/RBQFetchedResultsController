//
//  ParentObject.m
//  RBQFRCDynamicExample
//
//  Created by Adam Fish on 8/26/15.
//  Copyright (c) 2015 Adam Fish. All rights reserved.
//

#import "ParentObject.h"

@implementation ParentObject

// Specify default values for properties

+ (NSDictionary *)defaultPropertyValues
{
    return @{@"key":@""};
}

+ (NSString *)primaryKey
{
    return @"key";
}

@end
