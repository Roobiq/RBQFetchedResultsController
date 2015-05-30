//
//  RBQFetchedResultsSectionInfoTests.m
//  RBQFetchedResultsControllerExample
//
//  Created by AsanoYuki on 2015/05/28.
//  Copyright (c) 2015年 Roobiq. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "RBQFetchedResultsController.h"
#import "TestObject.h"

@interface RBQFetchedResultsSectionInfoTests : XCTestCase

@end

@implementation RBQFetchedResultsSectionInfoTests

#pragma mark - Setup

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
            testObject.title = @"title";
            testObject.inTable = YES;
            testObject.sortIndex = i;
            if (i % 2 == 0) {
                testObject.sectionName = @"section 1";
            } else {
                testObject.sectionName = @"section 2";
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

#pragma mark - Utility 

- (RBQFetchedResultsSectionInfo *)createFetchedResultsSectionInfo {
    SEL selector = NSSelectorFromString(@"createSectionWithName:sectionNameKeyPath:fetchRequest:");
    NSMethodSignature *signature = [[RBQFetchedResultsSectionInfo class] methodSignatureForSelector:selector];
    
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
    [invocation setSelector:selector];
    [invocation setTarget:[RBQFetchedResultsSectionInfo class]];
    
    NSString *sectionName = @"section 1";
    NSString *sectionNameKeyPath = @"sectionName";
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"inTable = YES"];
    RBQFetchRequest *fetchRequest = [RBQFetchRequest fetchRequestWithEntityName:@"TestObject" inRealm:[RLMRealm defaultRealm] predicate:predicate];
    
    [invocation setArgument:&sectionName atIndex:2];
    [invocation setArgument:&sectionNameKeyPath atIndex:3];
    [invocation setArgument:&fetchRequest atIndex:4];
    [invocation invoke];
    
    RBQFetchedResultsSectionInfo __unsafe_unretained *sectionInfo;
    [invocation getReturnValue:&sectionInfo];
    
    return sectionInfo;
}

#pragma mark - Test Case

- (void)testInitializeFetchedResultsSectionInfo {
    RBQFetchedResultsSectionInfo *sectionInfo = [self createFetchedResultsSectionInfo];
    XCTAssertNotNil(sectionInfo);
    XCTAssert([sectionInfo isKindOfClass:[RBQFetchedResultsSectionInfo class]]);
}

- (void)testObjectsProperty {
    RBQFetchedResultsSectionInfo *sectionInfo = [self createFetchedResultsSectionInfo];
    RLMResults *results = sectionInfo.objects;
    
    XCTAssert(sectionInfo.numberOfObjects == 5);
    XCTAssert(results.count == 5);
    for (TestObject *testObject in results) {
        XCTAssert([testObject.sectionName isEqualToString:@"section 1"]);
        XCTAssert(testObject.inTable == YES);
    }
}

@end
