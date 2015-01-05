//
//  RBQFetchRequest.h
//  RBQFetchedResultsControllerTest
//
//  Created by Lauren Smith on 1/2/15.
//  Copyright (c) 2015 Roobiq. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Realm/Realm.h>

@class RBQFetchRequest;

@interface RBQFetchRequest : NSObject

// Realm Class name
@property (nonatomic, readonly, strong) NSString *entityName;

@property (nonatomic, strong) NSPredicate *predicate;

// Array of RLMSortDescriptors
@property(nonatomic, strong) NSArray *sortDescriptors;

+ (RBQFetchRequest *)fetchRequestWithEntityName:(NSString *)entityName
                                      predicate:(NSPredicate *)predicate;

- (instancetype)initWithEntityName:(NSString *)entityName;

@end
