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
#import "RBQTestCase.h"

@interface RBQFetchedResultsControllerTests : RBQTestCase

@end

@implementation RBQFetchedResultsControllerTests

- (void)testPerformFetch
{
    [self insertDifferentSectionNameTestObject];
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
    [self insertDifferentSectionNameTestObject];
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
    [self insertDifferentSectionNameTestObject];
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
    [self insertDifferentSectionNameTestObject];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"inTable = YES"];
    RBQFetchRequest *fetchRequest = [RBQFetchRequest fetchRequestWithEntityName:@"TestObject" inRealm:[RLMRealm defaultRealm] predicate:predicate];
    RLMSortDescriptor *sectionNameSortDescriptor = [RLMSortDescriptor sortDescriptorWithProperty:@"sectionName" ascending:YES];
    fetchRequest.sortDescriptors = @[sectionNameSortDescriptor];
    RBQFetchedResultsController *fetchedResultsController = [[RBQFetchedResultsController alloc] initWithFetchRequest:fetchRequest sectionNameKeyPath:@"sectionName" cacheName:@"cache"];
    [fetchedResultsController performFetch];
    XCTAssert(fetchedResultsController.fetchedObjects.count == 10);
    NSPredicate *anotherPredicate = [NSPredicate predicateWithFormat:@"inTable = NO"];
    RBQFetchRequest *anotherFetchRequest = [RBQFetchRequest fetchRequestWithEntityName:@"TestObject" inRealm:[RLMRealm defaultRealm] predicate: anotherPredicate];
    [fetchedResultsController updateFetchRequest:anotherFetchRequest sectionNameKeyPath:@"sectionName" andPerformFetch:YES];
    XCTAssert(fetchedResultsController.fetchedObjects.count == 0);
}

@end
