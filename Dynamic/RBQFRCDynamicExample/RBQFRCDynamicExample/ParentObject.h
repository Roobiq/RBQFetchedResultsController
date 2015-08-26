//
//  ParentObject.h
//  RBQFRCDynamicExample
//
//  Created by Adam Fish on 8/26/15.
//  Copyright (c) 2015 Adam Fish. All rights reserved.
//

#import <Realm/Realm.h>
#import "TestObject.h"

@interface ParentObject : RLMObject

@property NSString *key;

@property RLMArray<TestObject> *testObjects;

@end

// This protocol enables typed collections. i.e.:
// RLMArray<ParentObject>
RLM_ARRAY_TYPE(ParentObject)
