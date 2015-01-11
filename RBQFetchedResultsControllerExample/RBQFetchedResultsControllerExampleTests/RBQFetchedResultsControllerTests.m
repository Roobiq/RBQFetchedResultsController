//
//  RBQFetchedResultsControllerTests.m
//  RBQFetchedResultsControllerExample
//
//  Created by Adam Fish on 1/10/15.
//  Copyright (c) 2015 Roobiq. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import "RBQFetchedResultsController.h"
#import "RBQRealmNotificationManager.h"
#import "TestObject.h"

@interface RBQFetchedResultsControllerTests : XCTestCase <RBQFetchedResultsControllerDelegate>

@property (strong, nonatomic) XCTestExpectation *controllerWillChangeContentExpectation;
@property (strong, nonatomic) XCTestExpectation *controllerDidChangeObjectExpectation;
@property (strong, nonatomic) XCTestExpectation *controllerDidChangeSectionExpectation;
@property (strong, nonatomic) XCTestExpectation *controllerDidChangeContentExpectation;

@property (strong, nonatomic) RLMRealm *inMemoryRealm;
@property (strong, nonatomic) RLMRealm *inMemoryRealmCache;
@property (strong, nonatomic) RBQFetchedResultsController *fetchedResultsController;

@end

@implementation RBQFetchedResultsControllerTests

- (void)setUp
{
    [super setUp];
    
    // Setup the DB
    self.inMemoryRealm = [RLMRealm inMemoryRealmWithIdentifier:@"defaultRealm"];
    
    self.inMemoryRealmCache = [RLMRealm inMemoryRealmWithIdentifier:@"cacheRealm"];
    
    [self.inMemoryRealm beginWriteTransaction];
    
    [self.inMemoryRealm deleteAllObjects];
    
    for (NSUInteger i = 0; i < 1000; i++) {
        
        NSString *title = [NSString stringWithFormat:@"Cell %lu", (unsigned long)i];
        
        TestObject *object = [TestObject testObjectWithTitle:title sortIndex:i inTable:YES];
        
        if (i < 10) {
            object.sectionName = @"First Section";
        }
        else {
            object.sectionName = @"Second Section";
        }
        
        [self.inMemoryRealm addObject:object];
    }
    
    [self.inMemoryRealm commitWriteTransaction];
    
    [self.inMemoryRealmCache beginWriteTransaction];
    
    [self.inMemoryRealmCache deleteAllObjects];
    
    [self.inMemoryRealmCache commitWriteTransaction];
    
    if (!self.fetchedResultsController) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"inTable = YES"];
        
        RBQFetchRequest *fetchRequest = [RBQFetchRequest fetchRequestWithEntityName:@"TestObject"
                                                                      inMemoryRealm:self.inMemoryRealm
                                                                          predicate:predicate];
        
        RLMSortDescriptor *sortDescriptor = [RLMSortDescriptor sortDescriptorWithProperty:@"sortIndex"
                                                                                ascending:YES];
        
        RLMSortDescriptor *sortDescriptorSection = [RLMSortDescriptor sortDescriptorWithProperty:@"sectionName"
                                                                                       ascending:YES];
        
        fetchRequest.sortDescriptors = @[sortDescriptorSection,sortDescriptor];
        
        self.fetchedResultsController =
        [[RBQFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                               sectionNameKeyPath:@"sectionName"
                                               inMemoryRealmCache:self.inMemoryRealmCache];
        
        self.fetchedResultsController.delegate = self;
    }
    
    [self.fetchedResultsController performFetch];
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
    
    self.controllerWillChangeContentExpectation = nil;
    self.controllerDidChangeObjectExpectation = nil;
    self.controllerDidChangeSectionExpectation = nil;
    self.controllerDidChangeContentExpectation = nil;
}

- (void)testControllerWillChangeContent
{
    self.controllerWillChangeContentExpectation = [self expectationWithDescription:@"FRC Will Change Content Fired"];
    self.controllerDidChangeContentExpectation = [self expectationWithDescription:@"FRC Did Change Content Fired"];
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    [self deleteObjectAtIndexPath:indexPath];
    
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        XCTAssertNil(error, @"error should not be nil");
    }];
}

- (void)testControllerDidChangeObject
{
    self.controllerDidChangeObjectExpectation = [self expectationWithDescription:@"FRC Did Change Object Fired"];
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    [self deleteObjectAtIndexPath:indexPath];
    
    [self waitForExpectationsWithTimeout:5 handler:^(NSError *error) {
        XCTAssertNil(error, @"error should not be nil");
    }];
}

- (void)testControllerDidChangeSection
{
    self.controllerDidChangeSectionExpectation = [self expectationWithDescription:@"FRC Did Change Section Fired"];
    
    // Test deleting a section
    RLMResults *objectInFirstSection = [TestObject objectsInRealm:self.inMemoryRealm
                                                            where:@"%K == %@",@"sectionName",@"First Section"];
    
    [self.inMemoryRealm beginWriteTransaction];
    
    for (TestObject *object in objectInFirstSection) {
        if (!object.invalidated) {
            [[RBQRealmNotificationManager managerForInMemoryRealm:self.inMemoryRealm] willDeleteObject:object];
            
            [self.inMemoryRealm deleteObject:object];
        }
    }
    
    [self.inMemoryRealm commitWriteTransaction];
    
    [self waitForExpectationsWithTimeout:5 handler:^(NSError *error) {
        XCTAssertNil(error, @"error should not be nil");
    }];
}

- (void)testControllerDidChangeContent
{
    self.controllerDidChangeContentExpectation = [self expectationWithDescription:@"FRC Did Change Content Fired"];
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    [self deleteObjectAtIndexPath:indexPath];
    
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        XCTAssertNil(error, @"error should not be nil");
    }];
}

#pragma - Actions

- (void)deleteObjectAtIndexPath:(NSIndexPath *)indexPath
{
    TestObject *object = [self.fetchedResultsController objectInRealm:self.inMemoryRealm
                                                          atIndexPath:indexPath];
    [self.inMemoryRealm beginWriteTransaction];
    
    [[RBQRealmNotificationManager managerForInMemoryRealm:self.inMemoryRealm] willDeleteObject:object];
    
    [self.inMemoryRealm deleteObject:object];
    
    [self.inMemoryRealm commitWriteTransaction];
}

#pragma mark - <RBQFetchedResultsControllerDelegate>

- (void)controllerWillChangeContent:(RBQFetchedResultsController *)controller
{
    [self.controllerWillChangeContentExpectation fulfill];
}

- (void)controller:(RBQFetchedResultsController *)controller
   didChangeObject:(RBQSafeRealmObject *)anObject
       atIndexPath:(NSIndexPath *)indexPath
     forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{
    
    switch(type) {
            
        case NSFetchedResultsChangeInsert:
        {
            NSLog(@"Inserting at path %@", newIndexPath);
            break;
        }
        case NSFetchedResultsChangeDelete:
        {
            NSLog(@"Deleting at path %ld", (long)indexPath.row);
            break;
        }
        case NSFetchedResultsChangeUpdate:
            NSLog(@"Updating at path %@", indexPath);
            break;
            
        case NSFetchedResultsChangeMove:
            NSLog(@"Moving from path %@ to %@", indexPath, newIndexPath);
            break;
    }
    
    [self.controllerDidChangeObjectExpectation fulfill];
}

- (void)controller:(RBQFetchedResultsController *)controller
  didChangeSection:(NSString *)sectionName
           atIndex:(NSUInteger)sectionIndex
     forChangeType:(NSFetchedResultsChangeType)type
{
    if (type == NSFetchedResultsChangeInsert) {
        NSLog(@"Inserting section at %lu", (unsigned long)sectionIndex);
    }
    else if (type == NSFetchedResultsChangeDelete) {
        NSLog(@"Deleting section at %lu", (unsigned long)sectionIndex);
    }

    [self.controllerDidChangeSectionExpectation fulfill];
}

- (void)controllerDidChangeContent:(RBQFetchedResultsController *)controller
{
    [self.controllerDidChangeContentExpectation fulfill];
}

@end
