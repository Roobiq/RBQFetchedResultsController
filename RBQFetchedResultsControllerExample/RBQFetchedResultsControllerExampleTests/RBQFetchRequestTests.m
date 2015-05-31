//
//  RBQFetchRequestTests.m
//  RBQFetchedResultsControllerExample
//
//  Created by AsanoYuki on 2015/05/27.
//  Copyright (c) 2015年 Roobiq. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "RBQFetchRequest.h"
#import "RLMRealm.h"
#import "TestObject.h"
#import "RBQTestCase.h"

@interface RBQFetchRequestTests : RBQTestCase

@end

@implementation RBQFetchRequestTests

- (void)testVerifyEnityNameObjC
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"inTable = YES"];
    
    RBQFetchRequest *fetchRequest = [RBQFetchRequest fetchRequestWithEntityName:@"TestObject"
                                                                        inRealm:[RLMRealm defaultRealm]
                                                                      predicate:predicate];
    
    XCTAssert([fetchRequest.entityName isEqualToString:@"TestObject"]);
}

// TODO: testVerifyEntityNameSwift

- (void)testFetchObjects
{
    [self insertDifferentInTableTestObject];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"inTable = YES"];
    
    RBQFetchRequest *fetchRequest = [RBQFetchRequest fetchRequestWithEntityName:@"TestObject"
                                                                        inRealm:[RLMRealm defaultRealm]
                                                                      predicate:predicate];
    
    RLMSortDescriptor *sortDescriptor = [RLMSortDescriptor sortDescriptorWithProperty:@"sortIndex"
                                                                            ascending:YES];
    fetchRequest.sortDescriptors = @[sortDescriptor];
    
    RLMResults *results = [fetchRequest fetchObjects];
    
    TestObject *firstObject = results.firstObject;
    
    XCTAssert(results.count == 5);
    XCTAssert([firstObject.key isEqualToString:@"key0"]);
}

- (void)testEvaluateObject
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"inTable = YES"];
    
    RBQFetchRequest *fetchRequest = [RBQFetchRequest fetchRequestWithEntityName:@"TestObject"
                                                                        inRealm:[RLMRealm defaultRealm]
                                                                      predicate:predicate];
    
    TestObject *testObject = [[TestObject alloc] init];
    
    testObject.key = @"key";
    testObject.inTable = YES;
    
    XCTAssert([fetchRequest evaluateObject:testObject]);
}

- (void)testEvaluateObjectFailed
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"inTable = YES"];
    
    RBQFetchRequest *fetchRequest = [RBQFetchRequest fetchRequestWithEntityName:@"TestObject"
                                                                        inRealm:[RLMRealm defaultRealm]
                                                                      predicate:predicate];
    
    TestObject *testObject = [[TestObject alloc] init];
    
    testObject.key = @"key";
    testObject.inTable = NO;
    
    XCTAssertFalse([fetchRequest evaluateObject:testObject]);
}

@end
