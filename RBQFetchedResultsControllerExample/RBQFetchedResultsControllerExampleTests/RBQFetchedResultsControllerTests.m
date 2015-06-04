//
//  RBQFetchedResultsControllerTests.m
//  RBQFetchedResultsControllerExample
//
//  Created by AsanoYuki on 2015/05/29.
//  Copyright (c) 2015年 Roobiq. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <UIKit/UIKit.h>
#import "RBQFetchedResultsController.h"
#import "TestObject.h"

@interface RBQFetchedResultsControllerTests : XCTestCase

@end

@implementation RBQFetchedResultsControllerTests

- (void)setUp
{
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
            testObject.inTable = YES;
            testObject.title = @"title";
            testObject.sortIndex = i;
            if (i % 2 == 0) {
                testObject.sectionName = @"section 1";
            } else {
                testObject.sectionName = @"section 2";
            }
            [[RLMRealm defaultRealm] addObject:testObject];
        }
    }];
    
    [RBQFetchedResultsController deleteCacheWithName:@"cache"];
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
    [[RLMRealm defaultRealm] transactionWithBlock:^{
        [[RLMRealm defaultRealm] deleteAllObjects];
    }];
}

- (void)testPerformFetch
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"inTable = YES"];
    RBQFetchRequest *fetchRequest = [RBQFetchRequest fetchRequestWithEntityName:@"TestObject" inRealm:[RLMRealm defaultRealm] predicate:predicate];
    RLMSortDescriptor *sectionNameSortDescriptor = [RLMSortDescriptor sortDescriptorWithProperty:@"sectionName" ascending:YES];
    fetchRequest.sortDescriptors = @[sectionNameSortDescriptor];
    RBQFetchedResultsController *fetchedResultsController = [[RBQFetchedResultsController alloc] initWithFetchRequest:fetchRequest sectionNameKeyPath:@"sectionName" cacheName:@"cache"];
    [fetchedResultsController performFetch];
    
    XCTAssert([fetchedResultsController numberOfSections] == 2);
    XCTAssert([fetchedResultsController.sectionNameKeyPath isEqualToString:@"sectionName"]);
    XCTAssert([fetchedResultsController.cacheName isEqualToString:@"cache"]);
    XCTAssert(fetchedResultsController.fetchedObjects.count == 10);
}

- (void)testPeformFetchWithoutSortDescriptor
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"inTable = YES"];
    RBQFetchRequest *fetchRequest = [RBQFetchRequest fetchRequestWithEntityName:@"TestObject" inRealm:[RLMRealm defaultRealm] predicate:predicate];
    RBQFetchedResultsController *fetchedResultsController = [[RBQFetchedResultsController alloc] initWithFetchRequest:fetchRequest sectionNameKeyPath:@"sectionName" cacheName:@"cache"];
    [fetchedResultsController performFetch];
    
    XCTAssert([fetchedResultsController numberOfSections] == 10);
    XCTAssert([fetchedResultsController.sectionNameKeyPath isEqualToString:@"sectionName"]);
    XCTAssert([fetchedResultsController.cacheName isEqualToString:@"cache"]);
    XCTAssert(fetchedResultsController.fetchedObjects.count == 10);
}

- (void)testDeleteWithCacheName
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"inTable = YES"];
    RBQFetchRequest *fetchRequest = [RBQFetchRequest fetchRequestWithEntityName:@"TestObject" inRealm:[RLMRealm defaultRealm] predicate:predicate];
    RLMSortDescriptor *sectionNameSortDescriptor = [RLMSortDescriptor sortDescriptorWithProperty:@"sectionName" ascending:YES];
    fetchRequest.sortDescriptors = @[sectionNameSortDescriptor];
    RBQFetchedResultsController *fetchedResultsController = [[RBQFetchedResultsController alloc] initWithFetchRequest:fetchRequest sectionNameKeyPath:@"sectionName" cacheName:@"cache"];
    [fetchedResultsController performFetch];
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    TestObject *testObject = [fetchedResultsController objectAtIndexPath:indexPath];
    
    XCTAssert([fetchedResultsController.cacheName isEqualToString:@"cache"]);
    XCTAssert(fetchedResultsController.fetchedObjects.count == 10);
    XCTAssert([testObject.sectionName isEqualToString:@"section 1"]);
    XCTAssert(testObject.sortIndex == 0);
    
    [RBQFetchedResultsController deleteCacheWithName:@"cache"];
    
    XCTAssert([fetchedResultsController.cacheName isEqualToString:@"cache"]);
    XCTAssert(fetchedResultsController.fetchedObjects.count == 10);
    XCTAssertNil([fetchedResultsController objectAtIndexPath:indexPath]);
}

// TODO: - deleteWithCacheName pass nil

- (void)testUpdateFetchRequestSectionNameKeyPathAndPeformFetch
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"inTable = YES"];
    RBQFetchRequest *fetchRequest = [RBQFetchRequest fetchRequestWithEntityName:@"TestObject" inRealm:[RLMRealm defaultRealm] predicate:predicate];
    RLMSortDescriptor *sectionNameSortDescriptor = [RLMSortDescriptor sortDescriptorWithProperty:@"sectionName" ascending:YES];
    fetchRequest.sortDescriptors = @[sectionNameSortDescriptor];
    RBQFetchedResultsController *fetchedResultsController = [[RBQFetchedResultsController alloc] initWithFetchRequest:fetchRequest sectionNameKeyPath:@"sectionName" cacheName:@"cache"];
    [fetchedResultsController performFetch];
    XCTAssert(fetchedResultsController.fetchedObjects.count == 10);
    NSPredicate *anotherPredicate = [NSPredicate predicateWithFormat:@"inTable = NO"];
    RBQFetchRequest *anotherFetchRequest = [RBQFetchRequest fetchRequestWithEntityName:@"TestObject" inRealm:[RLMRealm defaultRealm] predicate: anotherPredicate];
    [fetchedResultsController updateFetchRequest:anotherFetchRequest sectionNameKeyPath:@"sectionName" andPeformFetch:YES];
    XCTAssert(fetchedResultsController.fetchedObjects.count == 0);
}

@end
