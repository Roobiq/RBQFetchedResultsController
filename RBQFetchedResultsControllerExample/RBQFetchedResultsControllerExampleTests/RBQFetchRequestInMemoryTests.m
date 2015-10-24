//
//  RBQFetchRequestInMemoryTests.m
//  RBQFetchedResultsControllerExample
//
//  Created by Adam Fish on 5/29/15.
//  Copyright (c) 2015 Roobiq. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import "RBQFetchRequest.h"
#import <Realm/Realm.h>
#import "TestObject.h"

@interface RBQFetchRequestInMemoryTests : XCTestCase

@property (strong, nonatomic) RLMRealm *inMemoryRealm;

@end

@implementation RBQFetchRequestInMemoryTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    
    // Setup the DB (use random strings to create new versions each time)
    RLMRealmConfiguration *inMemoryConfig = [RLMRealmConfiguration defaultConfiguration];
    
    inMemoryConfig.inMemoryIdentifier = [[NSProcessInfo processInfo] globallyUniqueString];
    
    self.inMemoryRealm = [RLMRealm realmWithConfiguration:inMemoryConfig error:nil];
    
    [self.inMemoryRealm transactionWithBlock:^{
        
        [self.inMemoryRealm deleteAllObjects];
        
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
            
            [self.inMemoryRealm addObject:testObject];
        }
    }];
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
    
    RLMRealm *realm = self.inMemoryRealm;
    
    [realm transactionWithBlock:^{
        
        [realm deleteAllObjects];
    }];
}

- (void)testVerifyEnityNameObjC
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"inTable = YES"];
    
    RBQFetchRequest *fetchRequest = [RBQFetchRequest fetchRequestWithEntityName:@"TestObject"
                                                                        inRealm:self.inMemoryRealm
                                                                      predicate:predicate];
    
    XCTAssert([fetchRequest.entityName isEqualToString:@"TestObject"]);
}

// TODO: testVerifyEntityNameSwift

- (void)testFetchObjects
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"inTable = YES"];
    
    RBQFetchRequest *fetchRequest = [RBQFetchRequest fetchRequestWithEntityName:@"TestObject"
                                                                        inRealm:self.inMemoryRealm
                                                                      predicate:predicate];
    
    RLMSortDescriptor *sortDescriptor = [RLMSortDescriptor sortDescriptorWithProperty:@"sortIndex"
                                                                            ascending:YES];
    
    fetchRequest.sortDescriptors = @[sortDescriptor];
    
    id<RLMCollection> results = [fetchRequest fetchObjects];
    
    TestObject *firstObject = results.firstObject;
    
    XCTAssert(results.count == 5);
    XCTAssert([firstObject.key isEqualToString:@"key0"]);
}

- (void)testEvaluateObject
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"inTable = YES"];
    
    RBQFetchRequest *fetchRequest = [RBQFetchRequest fetchRequestWithEntityName:@"TestObject"
                                                                        inRealm:self.inMemoryRealm
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
                                                                        inRealm:self.inMemoryRealm
                                                                      predicate:predicate];
    
    TestObject *testObject = [[TestObject alloc] init];
    
    testObject.key = @"key";
    testObject.inTable = NO;
    
    XCTAssertFalse([fetchRequest evaluateObject:testObject]);
}

@end
