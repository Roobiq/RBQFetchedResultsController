//
//  RBQFetchRequest.m
//  RBQFetchedResultsControllerTest
//
//  Created by Lauren Smith on 1/2/15.
//  Copyright (c) 2015 Roobiq. All rights reserved.
//

#import "RBQFetchRequest.h"

@implementation RBQFetchRequest

+ (RBQFetchRequest *)fetchRequestWithEntityName:(NSString *)entityName
                                      predicate:(NSPredicate *)predicate
{
    RBQFetchRequest *fetchRequest = [[RBQFetchRequest alloc] initWithEntityName:entityName];
    fetchRequest.predicate = predicate;
    
    return fetchRequest;
}

- (instancetype)initWithEntityName:(NSString *)entityName
{
    self = [super init];
    
    if (self) {
        _entityName = entityName;
    }
    
    return self;
}

@end
