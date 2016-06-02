//
//  RBQTestCase.m
//  RBQFetchedResultsControllerExample
//
//  Created by AsanoYuki on 2015/05/30.
//  Copyright (c) 2015年 Roobiq. All rights reserved.
//

#import "RBQTestCase.h"
#import <Realm/RLMRealm.h>
#import "TestObject.h"

static NSString *testRealmFileName = @"test.realm";

@interface RBQTestCase()

@property (nonatomic, strong) RLMRealm *realm;

@end

@implementation RBQTestCase

- (void)setUp
{
    [super setUp];

    NSArray *writablePaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsPath = [writablePaths lastObject];
    NSString *testRealmFile = [documentsPath stringByAppendingPathComponent:testRealmFileName];
    
    RLMRealmConfiguration *defaultConfig = [RLMRealmConfiguration defaultConfiguration];
    defaultConfig.fileURL = [NSURL fileURLWithPath:testRealmFile];
    
    [RLMRealmConfiguration setDefaultConfiguration:defaultConfig];
    
    if (self.inMemory) {
        RLMRealmConfiguration *inMemoryConfig = [RLMRealmConfiguration defaultConfiguration];
        inMemoryConfig.inMemoryIdentifier = [[NSProcessInfo processInfo] globallyUniqueString];
        self.realm = [RLMRealm realmWithConfiguration:inMemoryConfig error:nil];
    }
    else {
        self.realm = [RLMRealm defaultRealm];
    }
    
    [self.realm transactionWithBlock:^{
        [[RLMRealm defaultRealm] deleteAllObjects];
    }];
}

- (void)tearDown
{
    [super tearDown];
    
    [self.realm transactionWithBlock:^{
        [[RLMRealm defaultRealm] deleteAllObjects];
    }];
}

#pragma mark - Insert objects in Realm

- (void)insertDifferentSectionNameTestObject
{
    [self.realm transactionWithBlock:^{
        for (int i=0; i < 10; i++) {
            TestObject *testObject = [[TestObject alloc] init];
            testObject.key = [NSString stringWithFormat:@"key%d", i];
            testObject.inTable = YES;
            testObject.title = @"title";
            testObject.sortIndex = i;
            
            if (i % 2 == 0) {
                testObject.sectionName = @"section 1";
            }
            else {
                testObject.sectionName = @"section 2";
            }
            
            [[RLMRealm defaultRealm] addObject:testObject];
        }
    }];
}

- (void)insertDifferentInTableTestObject
{
    [self.realm transactionWithBlock:^{
        for (int i=0; i < 10; i++) {
            TestObject *testObject = [[TestObject alloc] init];
            testObject.key = [NSString stringWithFormat:@"key%d", i];
            testObject.sectionName = @"sectionName";
            testObject.title = @"title";
            testObject.sortIndex = i;
            
            if (i % 2 == 0) {
                testObject.inTable = YES;
            }
            else {
                testObject.inTable = NO;
            }
            
            [[RLMRealm defaultRealm] addObject:testObject];
        }
    }];
}

@end
