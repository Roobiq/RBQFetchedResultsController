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

/**
 *  This class is used by the RBQFetchedResultsController to represent the properties of the fetch. The RBQFetchRequest is specific to one RLMObject and uses an NSPredicate and array of RLMSortDescriptors to define the query.
 */
@interface RBQFetchRequest : NSObject

/**
 *  RLMObject class name for the fetch request
 */
@property (nonatomic, readonly) NSString *entityName;

/**
 *  The Realm in which the entity for the fetch request is persisted.
 */
@property (nonatomic, readonly) RLMRealm *realm;

/**
 *  Indicates whether the Realm for this RBQFetchRequest is an in-memory Realm.
 */
@property (nonatomic, readonly) BOOL isInMemoryRealm;

/**
 *  Predicate supported by Realm
 
    http://realm.io/docs/cocoa/0.89.2/#querying-with-predicates
 */
@property (nonatomic, strong) NSPredicate *predicate;

/**
 *  Array of RLMSortDescriptors
 
    http://realm.io/docs/cocoa/0.89.2/#ordering-results
 */
@property(nonatomic, strong) NSArray *sortDescriptors;


/**
 *  Constructor method to create a fetch request for a given entity name in a specific Realm.
 *
 *  @param entityName Class name for the RLMObject
 *  @param realm      RLMRealm in which the RLMObject is persisted
 *  @param predicate  NSPredicate that represents the search query
 *
 *  @return A new instance of RBQFetchRequest
 */
+ (RBQFetchRequest *)fetchRequestWithEntityName:(NSString *)entityName
                                        inRealm:(RLMRealm *)realm
                                      predicate:(NSPredicate *)predicate;

/**
 *  Constructor method to create a fetch request for a given entity name in an in-memory Realm.
 *
 *  @param entityName Class name for the RLMObject
 *  @param realm      In-memory RLMRealm in which the RLMObject is persisted
 *  @param predicate  NSPredicate that represents the search query
 *
 *  @return A new instance of RBQFetchRequest
 */
+ (RBQFetchRequest *)fetchRequestWithEntityName:(NSString *)entityName
                                  inMemoryRealm:(RLMRealm *)inMemoryRealm
                                      predicate:(NSPredicate *)predicate;

/**
 *  Retrieve all the RLMObjects for this fetch request
 *
 *  @return RLMResults for all the objects in the fetch request (not thread-safe).
 */
- (RLMResults *)fetchObjects;

/**
 *  Create RBQFetchRequest in RLMRealm instance with an entity name
 *
 *  @param entityName Class name for the RLMObject
 *  @param realm      RLMRealm in which the RLMObject is persisted
 *
 *  @return A new instance of RBQFetchRequest
 */
- (instancetype)initWithEntityName:(NSString *)entityName
                           inRealm:(RLMRealm *)realm;

@end
