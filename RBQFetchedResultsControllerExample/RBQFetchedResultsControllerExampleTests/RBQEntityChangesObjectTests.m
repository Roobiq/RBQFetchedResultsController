//
//  RBQEntityChangesObjectTests.m
//  RBQFetchedResultsControllerExample
//
//  Created by AsanoYuki on 2015/05/28.
//  Copyright (c) 2015年 Roobiq. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "RBQFetchedResultsController.h"
#import "RBQRealmNotificationManager.h"
#import "TestObject.h"

@interface RBQEntityChangesObjectTests : XCTestCase

@end

@implementation RBQEntityChangesObjectTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

#pragma mark - Utility

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"

- (RBQEntityChangesObject *)createEntityChangesObject
{
    SEL selector = NSSelectorFromString(@"createEntityChangeObjectWithClassName:");
    
    RBQEntityChangesObject *entityChangesObject = [[RBQEntityChangesObject class] performSelector:selector withObject:@"TestObject"];
    
    return entityChangesObject;
}

#pragma mark - Test Case

- (void)testInitializeEntityChangesObject
{
    RBQEntityChangesObject *entityChangesObject = [self createEntityChangesObject];
    
    XCTAssert([entityChangesObject.className isEqualToString:@"TestObject"]);
    XCTAssert([entityChangesObject.addedSafeObjects isKindOfClass:[NSSet class]]);
    XCTAssert([entityChangesObject.deletedSafeObjects isKindOfClass:[NSSet class]]);
    XCTAssert([entityChangesObject.changedSafeObjects isKindOfClass:[NSSet class]]);
}

- (void)testDidAddSafeObject
{
    RBQEntityChangesObject *entityChangesObject = [self createEntityChangesObject];
    
    SEL selector = NSSelectorFromString(@"didAddSafeObject:");
    
    RBQSafeRealmObject *safeObject = [[RBQSafeRealmObject alloc] initWithClassName:@"TestObject"
                                                                   primaryKeyValue:@"key"
                                                                    primaryKeyType:RLMPropertyTypeString
                                                                             realm:[RLMRealm defaultRealm]];
    
    XCTAssert(entityChangesObject.addedSafeObjects.count == 0);

    [entityChangesObject performSelector:selector withObject:safeObject];
    
    XCTAssert(entityChangesObject.addedSafeObjects.count == 1);
}

- (void)testWillDeleteSafeObject
{
    RBQEntityChangesObject *entityChangesObject = [self createEntityChangesObject];
    
    SEL selector = NSSelectorFromString(@"willDeleteSafeObject:");
    
    RBQSafeRealmObject *safeObject = [[RBQSafeRealmObject alloc] initWithClassName:@"TestObject"
                                                                   primaryKeyValue:@"key"
                                                                    primaryKeyType:RLMPropertyTypeString
                                                                             realm:[RLMRealm defaultRealm]];
    
    XCTAssert(entityChangesObject.deletedSafeObjects.count == 0);
    
    [entityChangesObject performSelector:selector withObject:safeObject];
    
    XCTAssert(entityChangesObject.deletedSafeObjects.count == 1);
}

- (void)testDidChangeSafeObject
{
    RBQEntityChangesObject *entityChangesObject = [self createEntityChangesObject];
    
    SEL selector = NSSelectorFromString(@"didChangeSafeObject:");
    
    RBQSafeRealmObject *safeObject = [[RBQSafeRealmObject alloc] initWithClassName:@"TestObject"
                                                                   primaryKeyValue:@"key"
                                                                    primaryKeyType:RLMPropertyTypeString
                                                                             realm:[RLMRealm defaultRealm]];
    
    XCTAssert(entityChangesObject.changedSafeObjects.count == 0);
    
    [entityChangesObject performSelector:selector withObject:safeObject];
    
    XCTAssert(entityChangesObject.changedSafeObjects.count == 1);
}
#pragma clang diagnostic pop

@end
