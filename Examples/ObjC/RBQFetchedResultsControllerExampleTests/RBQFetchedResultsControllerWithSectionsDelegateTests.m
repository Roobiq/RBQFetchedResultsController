//
//  RBQFetchedResultsControllerWithSectionsDelegateTests.m
//  RBQFetchedResultsControllerExample
//
//  Created by Adam Fish on 1/10/15.
//  Copyright (c) 2015 Roobiq. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import <objc/runtime.h>

#import "RBQFetchedResultsController.h"
#import "TestObject.h"

static char kAssociatedObjectKey;

@interface RBQFetchedResultsControllerWithSectionsDelegateTests : XCTestCase <RBQFetchedResultsControllerDelegate>

@property (strong, nonatomic) XCTestExpectation *controllerWillChangeContentExpectation;
@property (strong, nonatomic) XCTestExpectation *controllerDidChangeObjectExpectation;
@property (strong, nonatomic) XCTestExpectation *controllerDidChangeSectionExpectation;
@property (strong, nonatomic) XCTestExpectation *controllerDidChangeContentExpectation;

@property (strong, nonatomic) RLMRealm *inMemoryRealm;
@property (strong, nonatomic) RBQFetchedResultsController *fetchedResultsController;
@property (assign, nonatomic) NSUInteger count;

@end

@implementation RBQFetchedResultsControllerWithSectionsDelegateTests

- (void)setUp
{
    [super setUp];
    
    // Setup the DB (use random strings to create new versions each time)
    RLMRealmConfiguration *inMemoryConfig = [RLMRealmConfiguration defaultConfiguration];
    
    inMemoryConfig.inMemoryIdentifier = [[NSProcessInfo processInfo] globallyUniqueString];
    
    self.inMemoryRealm = [RLMRealm realmWithConfiguration:inMemoryConfig error:nil];
    
    // Load the DB with data
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
    
    // Setup the FRC
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"inTable = YES"];
    
    RBQFetchRequest *fetchRequest = [RBQFetchRequest fetchRequestWithEntityName:@"TestObject"
                                                                        inRealm:self.inMemoryRealm
                                                                      predicate:predicate];
    
    RLMSortDescriptor *sortDescriptor = [RLMSortDescriptor sortDescriptorWithProperty:@"sortIndex"
                                                                            ascending:YES];
    
    RLMSortDescriptor *sortDescriptorSection = [RLMSortDescriptor sortDescriptorWithProperty:@"sectionName"
                                                                                   ascending:YES];
    
    fetchRequest.sortDescriptors = @[sortDescriptorSection,sortDescriptor];
    
    self.fetchedResultsController =
    [[RBQFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                           sectionNameKeyPath:@"sectionName"
                                                    cacheName:nil];
    
    self.fetchedResultsController.delegate = self;
    
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
    
    self.fetchedResultsController = nil;
    self.count = 0;
}

- (void)testControllerWillChangeContent
{
    self.controllerWillChangeContentExpectation = [self expectationWithDescription:@"FRC Will Change Content Fired"];
    self.controllerDidChangeContentExpectation = [self expectationWithDescription:@"FRC Did Change Content Fired"];
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    [self deleteObjectAtIndexPath:indexPath];
    
    [self waitForExpectationsWithTimeout:5 handler:^(NSError *error) {
        
        XCTAssertNil(error, @"%@", error.localizedDescription);
    }];
}

- (void)testControllerDidChangeObject
{
    self.controllerDidChangeObjectExpectation = [self expectationWithDescription:@"FRC Did Change Object Fired"];
    self.controllerDidChangeContentExpectation = [self expectationWithDescription:@"FRC Did Change Content Fired"];
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    [self deleteObjectAtIndexPath:indexPath];
    
    [self waitForExpectationsWithTimeout:5 handler:^(NSError *error) {
        
        XCTAssertNil(error, @"%@", error.localizedDescription);
    }];
}

- (void)testControllerDidChangeSection
{
    self.controllerDidChangeObjectExpectation = [self expectationWithDescription:@"FRC Did Change Object Fired"];
    self.controllerDidChangeSectionExpectation = [self expectationWithDescription:@"FRC Did Change Section Fired"];
    self.controllerDidChangeContentExpectation = [self expectationWithDescription:@"FRC Did Change Content Fired"];
    
    // Test deleting a section
    RLMResults *objectInFirstSection = [TestObject objectsInRealm:self.inMemoryRealm
                                                            where:@"%K == %@",@"sectionName",@"First Section"];
    
    [self.inMemoryRealm beginWriteTransaction];
    
    [self.inMemoryRealm deleteObjects:objectInFirstSection];
    
    [self.inMemoryRealm commitWriteTransaction];
        
    [self waitForExpectationsWithTimeout:5 handler:^(NSError *error) {
        XCTAssertNil(error, @"%@", error.localizedDescription);
    }];
}

- (void)testControllerDidChangeContent
{
    self.controllerDidChangeContentExpectation = [self expectationWithDescription:@"FRC Did Change Content Fired"];
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    [self deleteObjectAtIndexPath:indexPath];
        
    [self waitForExpectationsWithTimeout:5 handler:^(NSError *error) {
        XCTAssertNil(error, @"%@", error.localizedDescription);
    }];
}

- (void)testControllerDidChangeObjects
{
    dispatch_semaphore_t sem = dispatch_semaphore_create(0);
    
    int maxCycles = 100;
    
    for (int i = 1; i <= maxCycles; i++) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
        
        TestObject *object = [self.fetchedResultsController objectAtIndexPath:indexPath];
        
        TestObject *copiedObject = [object copy];
        
        XCTestExpectation *deleteExpectation = [self expectationWithDescription:@""];
        
        objc_setAssociatedObject(self.fetchedResultsController, &kAssociatedObjectKey, deleteExpectation, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        
        [self.inMemoryRealm transactionWithBlock:^{
            [self.inMemoryRealm deleteObject:object];
        }];
        
        [self waitForExpectationsWithTimeout:5 handler:^(NSError *error) {
            
            XCTAssertNil(error, @"%@", error.localizedDescription);
        }];
        
        XCTestExpectation *insertExpectation = [self expectationWithDescription:@""];
        
        objc_setAssociatedObject(self.fetchedResultsController, &kAssociatedObjectKey, insertExpectation, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        
        [self.inMemoryRealm transactionWithBlock:^{
            [self.inMemoryRealm addObject:copiedObject];
        }];
        
        [self waitForExpectationsWithTimeout:5 handler:^(NSError *error) {
            
            XCTAssertNil(error, @"%@", error.localizedDescription);
        }];
        
        if (i == maxCycles - 1) {
            dispatch_semaphore_signal(sem);
        }
    }
    
    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
}

#pragma - Actions

- (void)deleteObjectAtIndexPath:(NSIndexPath *)indexPath
{
    TestObject *object = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    [self.inMemoryRealm beginWriteTransaction];
    
    [self.inMemoryRealm deleteObject:object];
    
    [self.inMemoryRealm commitWriteTransaction];
}

#pragma mark - <RBQFetchedResultsControllerDelegate>

- (void)controllerWillChangeContent:(RBQFetchedResultsController *)controller
{
    if (self.controllerWillChangeContentExpectation) {
        
        [self.controllerWillChangeContentExpectation fulfill];
    }
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
    
    XCTestExpectation *associatedExpectation = objc_getAssociatedObject(controller, &kAssociatedObjectKey);
    
    // Fulfilling an expectation prematurely seems to cause problems
    if (self.controllerDidChangeObjectExpectation &&
        !self.controllerDidChangeSectionExpectation) {
        
        [self.controllerDidChangeObjectExpectation fulfill];
    }
    else if (self.controllerDidChangeObjectExpectation &&
             self.controllerDidChangeSectionExpectation) {
        
        self.count ++;
        
        if (self.count == 10) {
            
            [self.controllerDidChangeObjectExpectation fulfill];
        }
    }
    else if (associatedExpectation) {
        [associatedExpectation fulfill];
        objc_setAssociatedObject(controller, &kAssociatedObjectKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
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

    if (self.controllerDidChangeSectionExpectation) {
        
        [self.controllerDidChangeSectionExpectation fulfill];
    }
}

- (void)controllerDidChangeContent:(RBQFetchedResultsController *)controller
{
    if (self.controllerDidChangeContentExpectation) {
        
        [self.controllerDidChangeContentExpectation fulfill];
    }
}

@end
