//
//  RBQRealmChangeLoggerTests.m
//  RBQFetchedResultsControllerExample
//
//  Created by AsanoYuki on 2015/05/27.
//  Copyright (c) 2015年 Roobiq. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "RBQRealmNotificationManager.h"
#import "TestObject.h"

@interface RBQRealmChangeLoggerTests : XCTestCase

@end

@implementation RBQRealmChangeLoggerTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
    
    RLMRealm *realm = [RLMRealm defaultRealm];
    
    // Reset Logger status with receive notification from realm
    [realm transactionWithBlock:^{
        
        [realm deleteAllObjects];
    }];
}

- (void)testDidAddObject
{
    RBQRealmChangeLogger *logger = [RBQRealmChangeLogger defaultLogger];
    
    TestObject *testObject = [[TestObject alloc] init];
    
    testObject.key = @"key";
    
    XCTAssert(logger.entityChanges.allKeys.count == 0);
    
    [logger didAddObject:testObject];
    
    NSDictionary *entityChanges = logger.entityChanges;
    
    RBQEntityChangesObject *entityChangesObject = entityChanges[@"TestObject"];
    
    XCTAssert([entityChangesObject.className isEqualToString:@"TestObject"]);
    XCTAssert(entityChangesObject.addedSafeObjects.count == 1);
    XCTAssert(entityChangesObject.deletedSafeObjects.count == 0);
    XCTAssert(entityChangesObject.changedSafeObjects.count == 0);
}

- (void)testDidAddObjects
{
    RBQRealmChangeLogger *logger = [RBQRealmChangeLogger defaultLogger];
    
    TestObject *testObject1 = [[TestObject alloc] init];
    TestObject *testObject2 = [[TestObject alloc] init];
    TestObject *testObject3 = [[TestObject alloc] init];
    
    testObject1.key = @"key1";
    testObject2.key = @"key2";
    testObject3.key = @"key3";
    
    XCTAssert(logger.entityChanges.allKeys.count == 0);
    
    [logger didAddObjects:@[testObject1, testObject2, testObject3]];
    
    NSDictionary *entityChanges = logger.entityChanges;
    
    RBQEntityChangesObject *entityChangesObject = entityChanges[@"TestObject"];
    
    XCTAssert([entityChangesObject.className isEqualToString:@"TestObject"]);
    XCTAssert(entityChangesObject.addedSafeObjects.count == 3);
    XCTAssert(entityChangesObject.deletedSafeObjects.count == 0);
    XCTAssert(entityChangesObject.changedSafeObjects.count == 0);
}

- (void)testWillDeleteObject
{
    RBQRealmChangeLogger *logger = [RBQRealmChangeLogger defaultLogger];
    
    TestObject *testObject = [[TestObject alloc] init];
    testObject.key = @"key";
    
    XCTAssert(logger.entityChanges.allKeys.count == 0);
    
    [logger willDeleteObject:testObject];
    
    NSDictionary *entityChanges = logger.entityChanges;
    
    RBQEntityChangesObject *entityChangesObject = entityChanges[@"TestObject"];
    
    XCTAssert([entityChangesObject.className isEqualToString:@"TestObject"]);
    XCTAssert(entityChangesObject.addedSafeObjects.count == 0);
    XCTAssert(entityChangesObject.deletedSafeObjects.count == 1);
    XCTAssert(entityChangesObject.changedSafeObjects.count == 0);
}

- (void)testWillDeleteObjects
{
    RBQRealmChangeLogger *logger = [RBQRealmChangeLogger defaultLogger];
    
    TestObject *testObject1 = [[TestObject alloc] init];
    TestObject *testObject2 = [[TestObject alloc] init];
    TestObject *testObject3 = [[TestObject alloc] init];
    
    testObject1.key = @"key1";
    testObject2.key = @"key2";
    testObject3.key = @"key3";
    
    XCTAssert(logger.entityChanges.allKeys.count == 0);
    
    [logger willDeleteObjects:@[testObject1, testObject2, testObject3]];
    
    NSDictionary *entityChanges = logger.entityChanges;
    
    RBQEntityChangesObject *entityChangesObject = entityChanges[@"TestObject"];
    
    XCTAssert([entityChangesObject.className isEqualToString:@"TestObject"]);
    XCTAssert(entityChangesObject.addedSafeObjects.count == 0);
    XCTAssert(entityChangesObject.deletedSafeObjects.count == 3);
    XCTAssert(entityChangesObject.changedSafeObjects.count == 0);
}

- (void)testDidChangeObject
{
    RBQRealmChangeLogger *logger = [RBQRealmChangeLogger defaultLogger];
    
    TestObject *testObject = [[TestObject alloc] init];
    testObject.key = @"key";
    
    XCTAssert(logger.entityChanges.allKeys.count == 0);
    
    [logger didChangeObject:testObject];
    
    NSDictionary *entityChanges = logger.entityChanges;
    
    RBQEntityChangesObject *entityChangesObject = entityChanges[@"TestObject"];
    
    XCTAssert([entityChangesObject.className isEqualToString:@"TestObject"]);
    XCTAssert(entityChangesObject.addedSafeObjects.count == 0);
    XCTAssert(entityChangesObject.deletedSafeObjects.count == 0);
    XCTAssert(entityChangesObject.changedSafeObjects.count == 1);
}

- (void)testDidChangeObjects
{
    RBQRealmChangeLogger *logger = [RBQRealmChangeLogger defaultLogger];
    
    TestObject *testObject1 = [[TestObject alloc] init];
    TestObject *testObject2 = [[TestObject alloc] init];
    TestObject *testObject3 = [[TestObject alloc] init];
    
    testObject1.key = @"key1";
    testObject2.key = @"key2";
    testObject3.key = @"key3";
    
    XCTAssert(logger.entityChanges.allKeys.count == 0);
    
    [logger didChangeObjects:@[testObject1, testObject2, testObject3]];
    
    NSDictionary *entityChanges = logger.entityChanges;
    
    RBQEntityChangesObject *entityChangesObject = entityChanges[@"TestObject"];
    
    XCTAssert([entityChangesObject.className isEqualToString:@"TestObject"]);
    XCTAssert(entityChangesObject.addedSafeObjects.count == 0);
    XCTAssert(entityChangesObject.deletedSafeObjects.count == 0);
    XCTAssert(entityChangesObject.changedSafeObjects.count == 3);
}

@end
