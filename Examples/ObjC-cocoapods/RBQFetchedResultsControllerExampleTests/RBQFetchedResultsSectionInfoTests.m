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
#import "RBQTestCase.h"

@interface RBQFetchedResultsSectionInfoTests : RBQTestCase

@end

@implementation RBQFetchedResultsSectionInfoTests

#pragma mark - Utility 

- (RBQFetchedResultsSectionInfo *)createFetchedResultsSectionInfo
{
    SEL selector = NSSelectorFromString(@"createSectionWithName:sectionNameKeyPath:fetchRequest:");
    
    NSMethodSignature *signature = [[RBQFetchedResultsSectionInfo class] methodSignatureForSelector:selector];
    
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
    
    [invocation setSelector:selector];
    [invocation setTarget:[RBQFetchedResultsSectionInfo class]];
    
    NSString *sectionName = @"section 1";
    
    NSString *sectionNameKeyPath = @"sectionName";
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"inTable = YES"];
    
    RBQFetchRequest *fetchRequest = [RBQFetchRequest fetchRequestWithEntityName:@"TestObject"
                                                                        inRealm:[RLMRealm defaultRealm]
                                                                      predicate:predicate];
    
    [invocation setArgument:&sectionName atIndex:2];
    [invocation setArgument:&sectionNameKeyPath atIndex:3];
    [invocation setArgument:&fetchRequest atIndex:4];
    
    [invocation invoke];
    
    RBQFetchedResultsSectionInfo __unsafe_unretained *sectionInfo;
    
    [invocation getReturnValue:&sectionInfo];
    
    return sectionInfo;
}

#pragma mark - Test Case

- (void)testInitializeFetchedResultsSectionInfo
{
    RBQFetchedResultsSectionInfo *sectionInfo = [self createFetchedResultsSectionInfo];
    
    XCTAssertNotNil(sectionInfo);
    XCTAssert([sectionInfo isKindOfClass:[RBQFetchedResultsSectionInfo class]]);
}

- (void)testObjectsProperty
{
    [self insertDifferentSectionNameTestObject];
    RBQFetchedResultsSectionInfo *sectionInfo = [self createFetchedResultsSectionInfo];
    
    id<RLMCollection> results = sectionInfo.objects;
    
    XCTAssert(sectionInfo.numberOfObjects == 5);
    XCTAssert(results.count == 5);
    
    for (TestObject *testObject in results) {
        
        XCTAssert([testObject.sectionName isEqualToString:@"section 1"]);
        XCTAssert(testObject.inTable == YES);
    }
}

@end
