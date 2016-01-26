//
//  RBQTestCase.h
//  RBQFetchedResultsControllerExample
//
//  Created by AsanoYuki on 2015/05/30.
//  Copyright (c) 2015年 Roobiq. All rights reserved.
//

#import <XCTest/XCTest.h>

@interface RBQTestCase : XCTestCase

@property (nonatomic) BOOL inMemory;

- (void)insertDifferentSectionNameTestObject;

- (void)insertDifferentInTableTestObject;

@end
