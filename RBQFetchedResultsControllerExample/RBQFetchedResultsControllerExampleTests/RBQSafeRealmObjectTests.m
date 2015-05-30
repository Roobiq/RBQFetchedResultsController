//
//  RBQSafeRealmObjectTests.m
//  RBQFetchedResultsControllerExample
//
//  Created by AsanoYuki on 2015/05/28.
//  Copyright (c) 2015年 Roobiq. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "RBQSafeRealmObject.h"
#import "TestObject.h"

@interface RBQSafeRealmObjectTests : XCTestCase

@end

@implementation RBQSafeRealmObjectTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    NSArray *writablePaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsPath = [writablePaths lastObject];
    NSString *testRealmFile = [documentsPath stringByAppendingPathComponent:@"test.realm"];
    
    [RLMRealm setDefaultRealmPath:testRealmFile];
    
    RLMRealm *realm = [RLMRealm defaultRealm];
    
    [realm transactionWithBlock:^{
        
        [realm deleteAllObjects];
    }];
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
    
    RLMRealm *realm = [RLMRealm defaultRealm];
    
    [realm transactionWithBlock:^{
        
        [realm deleteAllObjects];
    }];
}

- (void)testInitializeSafeObject
{
    RBQSafeRealmObject *safeObject = [[RBQSafeRealmObject alloc] initWithClassName:@"TestObject"
                                                                   primaryKeyValue:@"key"
                                                                    primaryKeyType:RLMPropertyTypeString
                                                                             realm:[RLMRealm defaultRealm]];
    
    XCTAssert([safeObject.className isEqualToString:@"TestObject"]);
    XCTAssert([safeObject.primaryKeyValue isEqualToString:@"key"]);
    XCTAssert(safeObject.primaryKeyType == RLMPropertyTypeString);
    XCTAssert([safeObject.realm isEqual:[RLMRealm defaultRealm]]);
}

- (void)testSafeObjectFromObjectIfObjectIsPersisted
{
    TestObject *testObject = [[TestObject alloc] init];
    testObject.key = @"key";
    testObject.sectionName = @"sectionName";
    testObject.title = @"title";
    testObject.sortIndex = 0;
    testObject.inTable = YES;
    
    RLMRealm *realm = [RLMRealm defaultRealm];
    
    [realm transactionWithBlock:^{
        
        [realm addObject:testObject];
    }];
    
    RBQSafeRealmObject *safeObject = [RBQSafeRealmObject safeObjectFromObject:testObject];
    
    XCTAssert([safeObject.className isEqualToString:@"TestObject"]);
    XCTAssert([safeObject.primaryKeyValue isEqualToString:@"key"]);
    XCTAssert(safeObject.primaryKeyType == RLMPropertyTypeString);
    XCTAssert([safeObject.realm isEqual:[RLMRealm defaultRealm]]);
}

- (void)testSafeObjectFromObjectIfObjectIsNotPersisted
{
    TestObject *testObject = [[TestObject alloc] init];
    testObject.key = @"key";
    
    RBQSafeRealmObject *safeObject = [RBQSafeRealmObject safeObjectFromObject:testObject];
    
    XCTAssert([safeObject.className isEqualToString:@"TestObject"]);
    XCTAssert([safeObject.primaryKeyValue isEqualToString:@"key"]);
    XCTAssert(safeObject.primaryKeyType == RLMPropertyTypeString);
    
    XCTAssertNil([safeObject valueForKeyPath:@"realmPath"]);
}

- (void)testThreadSafe
{
    XCTestExpectation *anotherThreadExpectation = [self expectationWithDescription:@"Wait the execution of antoher thread"];
    
    TestObject *testObject = [[TestObject alloc] init];
    testObject.key = @"key";
    testObject.sectionName = @"sectionName";
    testObject.title = @"title";
    testObject.sortIndex = 0;
    testObject.inTable = YES;
    
    RLMRealm *realm = [RLMRealm defaultRealm];
    
    [realm transactionWithBlock:^{
        
        [realm addObject:testObject];
    }];
    
    RBQSafeRealmObject *safeObject = [RBQSafeRealmObject safeObjectFromObject:testObject];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        
        XCTAssert([safeObject.className isEqualToString:@"TestObject"]);
        XCTAssert([safeObject.primaryKeyValue isEqualToString:@"key"]);
        XCTAssert(safeObject.primaryKeyType == RLMPropertyTypeString);
        XCTAssert([safeObject.realm isEqual:[RLMRealm defaultRealm]]);
        
        [anotherThreadExpectation fulfill];
    });
    
    [self waitForExpectationsWithTimeout:5 handler:nil];
}

- (void)testRLMRealmProperty
{
    TestObject *testObject = [[TestObject alloc] init];
    testObject.key = @"key";
    testObject.sectionName = @"sectionName";
    testObject.title = @"title";
    testObject.sortIndex = 0;
    testObject.inTable = YES;
    
    RLMRealm *realm = [RLMRealm defaultRealm];
    
    [realm transactionWithBlock:^{
        [realm addObject:testObject];
    }];
    
    TestObject *fetchedObject = [TestObject allObjects].firstObject;
    
    RBQSafeRealmObject *safeObject = [RBQSafeRealmObject safeObjectFromObject:testObject];
    
    XCTAssert([safeObject.RLMObject isEqualToObject:fetchedObject]);
}

- (void)testIsEqualToObject
{
    TestObject *testObject = [[TestObject alloc] init];
    testObject.key = @"key";
    testObject.sectionName = @"sectionName";
    testObject.title = @"title";
    testObject.sortIndex = 0;
    testObject.inTable = YES;
    
    RLMRealm *realm = [RLMRealm defaultRealm];
    
    [realm transactionWithBlock:^{
        
        [realm addObject:testObject];
    }];
    
    TestObject *fetchedObject = [TestObject allObjects].firstObject;
    
    RBQSafeRealmObject *safeObject1 = [RBQSafeRealmObject safeObjectFromObject:fetchedObject];
    RBQSafeRealmObject *safeObject2 = [RBQSafeRealmObject safeObjectFromObject:testObject];
    
    XCTAssert([safeObject1 isEqualToObject:safeObject2]);
}

@end
