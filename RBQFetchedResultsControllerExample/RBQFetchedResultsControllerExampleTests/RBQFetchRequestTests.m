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

@interface RBQFetchRequestTests : XCTestCase

@end

@implementation RBQFetchRequestTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    NSArray *writablePaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsPath = [writablePaths lastObject];
    NSString *testRealmFile = [documentsPath stringByAppendingPathComponent:@"test.realm"];
    [RLMRealm setDefaultRealmPath:testRealmFile];
    
    [[RLMRealm defaultRealm] transactionWithBlock:^{
        [[RLMRealm defaultRealm] deleteAllObjects];
        
        for (int i=0; i < 10; i++) {
            TestObject *testObject = [[TestObject alloc] init];
            testObject.key = [NSString stringWithFormat:@"key%d", i];
            testObject.sectionName = @"sectionName";
            testObject.title = @"title";
            testObject.sortIndex = i;
            if (i % 2 == 0) {
                testObject.inTable = YES;
            } else {
                testObject.inTable = NO;
            }
            [[RLMRealm defaultRealm] addObject:testObject];
        }
    }];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
    [[RLMRealm defaultRealm] transactionWithBlock:^{
        [[RLMRealm defaultRealm] deleteAllObjects];
    }];
}

- (void)testVerifyEnityNameObjC {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"inTable = YES"];
    RBQFetchRequest *fetchRequest = [RBQFetchRequest fetchRequestWithEntityName:@"TestObject" inRealm:[RLMRealm defaultRealm] predicate:predicate];
    
    XCTAssert([fetchRequest.entityName isEqualToString:@"TestObject"]);
}

// TODO: testVerifyEntityNameSwift

- (void)testFetchObjects {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"inTable = YES"];
    RBQFetchRequest *fetchRequest = [RBQFetchRequest fetchRequestWithEntityName:@"TestObject" inRealm:[RLMRealm defaultRealm] predicate:predicate];
    RLMSortDescriptor *sortDescriptor = [RLMSortDescriptor sortDescriptorWithProperty:@"sortIndex" ascending:YES];
    fetchRequest.sortDescriptors = @[sortDescriptor];
    
    RLMResults *results = [fetchRequest fetchObjects];
    TestObject *firstObject = results.firstObject;
    XCTAssert(results.count == 5);
    XCTAssert([firstObject.key isEqualToString:@"key0"]);
}

- (void)testEvaluateObject {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"inTable = YES"];
    RBQFetchRequest *fetchRequest = [RBQFetchRequest fetchRequestWithEntityName:@"TestObject" inRealm:[RLMRealm defaultRealm] predicate:predicate];
    
    TestObject *testObject = [[TestObject alloc] init];
    testObject.key = @"key";
    testObject.inTable = YES;
    
    XCTAssert([fetchRequest evaluateObject:testObject]);
}

- (void)testEvaluateObjectFailed {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"inTable = YES"];
    RBQFetchRequest *fetchRequest = [RBQFetchRequest fetchRequestWithEntityName:@"TestObject" inRealm:[RLMRealm defaultRealm] predicate:predicate];
    
    TestObject *testObject = [[TestObject alloc] init];
    testObject.key = @"key";
    testObject.inTable = NO;
    
    XCTAssertFalse([fetchRequest evaluateObject:testObject]);
}

@end
