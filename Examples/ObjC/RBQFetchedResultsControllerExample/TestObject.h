//
//  TestObject.h
//  RBQFetchedResultsControllerTest
//
//  Created by Lauren Smith on 1/2/15.
//  Copyright (c) 2015 Roobiq. All rights reserved.
//

#import <Realm/Realm.h>

@interface TestObject : RLMObject <NSCopying>

@property NSString *title;

@property NSInteger sortIndex;

@property NSString *sectionName;

@property NSString *key;

@property BOOL inTable;

+ (instancetype)testObjectWithTitle:(NSString *)title
                          sortIndex:(NSInteger)sortIndex
                            inTable:(BOOL)inTable;

@end

// This protocol enables typed collections. i.e.:
// RLMArray<TestObject>
RLM_ARRAY_TYPE(TestObject)
