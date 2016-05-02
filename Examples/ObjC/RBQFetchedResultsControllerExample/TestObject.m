//
//  TestObject.m
//  RBQFetchedResultsControllerTest
//
//  Created by Lauren Smith on 1/2/15.
//  Copyright (c) 2015 Roobiq. All rights reserved.
//

#import "TestObject.h"

@implementation TestObject

+ (NSString *)primaryKey
{
    return @"key";
}

// Specify default values for properties

//+ (NSDictionary *)defaultPropertyValues
//{
//    return @{};
//}

// Specify properties to ignore (Realm won't persist these)

//+ (NSArray *)ignoredProperties
//{
//    return @[];
//}

+ (instancetype)testObjectWithTitle:(NSString *)title
                          sortIndex:(NSInteger)sortIndex
                            inTable:(BOOL)inTable
{
    TestObject *object = [[TestObject alloc] init];
    object.sortIndex = sortIndex;
    object.title = title;
    object.key = [NSString stringWithFormat:@"%@%ld",title, (long)sortIndex];
    object.inTable = inTable;
    
    return object;
}

- (id)copyWithZone:(nullable NSZone *)zone
{
    TestObject *object = [[TestObject allocWithZone:zone] init];
    object.title = self.title;
    object.sortIndex = self.sortIndex;
    object.sectionName = self.sectionName;
    object.key = self.key;
    object.inTable = self.inTable;
    
    return object;
}

@end
