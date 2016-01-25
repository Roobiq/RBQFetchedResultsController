//
//  RBQFetchRequest.h
//  RBQFetchedResultsControllerTest
//
//  Created by Adam Fish on 1/2/15.
//  Copyright (c) 2015 Roobiq. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Realm/RLMCollection.h>

@class RBQFetchRequest, RLMRealm, RLMObject, RLMRealmConfiguration, RLMArray, RLMSortDescriptor;

#pragma mark - RBQFetchRequest

/**
 *  This class is used by the RBQFetchedResultsController to represent the properties of the fetch. The RBQFetchRequest is specific to one RLMObject and uses an NSPredicate and array of RLMSortDescriptors to define the query.
 */
@interface RBQFetchRequest : NSObject

/**
 *  RLMObject class name for the fetch request
 */
@property (nonatomic, readonly, nonnull) NSString *entityName;

/**
 *  The Realm in which the entity for the fetch request is persisted.
 */
@property (nonatomic, readonly, nonnull) RLMRealm *realm;

/**
 *  The configuration object used to create an instance of RLMRealm for the fetch request
 */
@property (nonatomic, readonly, nonnull) RLMRealmConfiguration *realmConfiguration;

/**
 *  Predicate supported by Realm
 *
 *  http://realm.io/docs/cocoa/0.89.2/#querying-with-predicates
 */
@property (nonatomic, strong, nullable) NSPredicate *predicate;

/**
 *  Array of RLMSortDescriptors
 *
 *  http://realm.io/docs/cocoa/0.89.2/#ordering-results
 */
@property(nonatomic, strong, nullable) NSArray<RLMSortDescriptor *> *sortDescriptors;


/**
 *  Constructor method to create a fetch request for a given entity name in a specific Realm.
 *
 *  @param entityName Class name for the RLMObject
 *  @param realm      RLMRealm in which the RLMObject is persisted (if passing in-memory Realm, make sure to keep a strong reference elsewhere since fetch request only stores the path)
 *  @param predicate  NSPredicate that represents the search query
 *
 *  @return A new instance of RBQFetchRequest
 */
+ (nonnull instancetype)fetchRequestWithEntityName:(nonnull NSString *)entityName
                                           inRealm:(nonnull RLMRealm *)realm
                                         predicate:(nullable NSPredicate *)predicate;

/**
 *  Retrieve all the RLMObjects for this fetch request in its realm.
 *
 *  @return RLMResults or RLMArray for all the objects in the fetch request (not thread-safe).
 */
- (nonnull id<RLMCollection>)fetchObjects;

/**
 *  Should this object be in our fetch results?
 *
 *  Intended to be used by the RBQFetchedResultsController to evaluate incremental changes. For
 *  simple fetch requests this just evaluates the NSPredicate, but subclasses may have a more
 *  complicated implementaiton.
 *
 *  @param object Realm object of appropriate type
 *
 *  @return YES if performing fetch would include this object
 */
- (BOOL)evaluateObject:(nonnull RLMObject *)object;

/**
 *  Create RBQFetchRequest in RLMRealm instance with an entity name
 *
 *  @param entityName Class name for the RLMObject
 *  @param realm      RLMRealm in which the RLMObject is persisted
 *
 *  @return A new instance of RBQFetchRequest
 */
- (nonnull instancetype)initWithEntityName:(nonnull NSString *)entityName
                                   inRealm:(nonnull RLMRealm *)realm;
@end
