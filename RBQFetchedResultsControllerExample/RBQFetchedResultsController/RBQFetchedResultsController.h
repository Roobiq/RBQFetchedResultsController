//
//  RBQFetchedResultsController.h
//  RBQFetchedResultsControllerTest
//
//  Created by Lauren Smith on 1/2/15.
//  Copyright (c) 2015 Roobiq. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RBQFetchRequest.h"
#import "RBQSafeRealmObject.h"

@import CoreData;

@class RBQFetchedResultsController;

#pragma mark - RBQFetchedResultsSectionInfo

// Object to use for relaying section info
@interface RBQFetchedResultsSectionInfo : NSObject

@property (nonatomic, readonly) NSUInteger numberOfObjects;
@property (nonatomic, readonly) RLMResults *objects;
@property (nonatomic, readonly) NSString *name;

@end

#pragma mark - RBQFetchedResultsControllerDelegate

@protocol RBQFetchedResultsControllerDelegate <NSObject>

@optional

- (void)controllerWillChangeContent:(RBQFetchedResultsController *)controller;

/**
 Notifies the delegate that a fetched object has been changed due to an add, remove, move, or
 update. Enables RBQFetchedResultsController change tracking.
 
 Changes are reported with the following heuristics:
 
  * On add and remove operations, only the added/removed object is reported. It’s assumed that all
    objects that come after the affected object are also moved, but these moves are not reported.
 
  * A move is reported when the changed attribute on the object is one of the sort descriptors used
    in the fetch request. An update of the object is assumed in this case, but no separate update
    message is sent to the delegate.
 
  * An update is reported when an object’s state changes, but the changed attributes aren’t part of
   the sort keys.
 
 @param controller controller instance that noticed the change on its fetched objects
 @param anObject changed object represented as a RBQSafeRealmObject for thread safety
 @param indexPath indexPath of changed object (nil for inserts)
 @param type indicates if the change was an insert, delete, move, or update
 @param newIndexPath the destination path for inserted or moved objects, nil otherwise
 */

- (void)controller:(RBQFetchedResultsController *)controller
   didChangeObject:(RBQSafeRealmObject *)anObject
       atIndexPath:(NSIndexPath *)indexPath
     forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath;

/**
 The fetched results controller reports changes to its section before changes to the fetched result
 objects.
 */
- (void)controller:(RBQFetchedResultsController *)controller
  didChangeSection:(RBQFetchedResultsSectionInfo *)section
           atIndex:(NSUInteger)sectionIndex
     forChangeType:(NSFetchedResultsChangeType)type;

- (void)controllerDidChangeContent:(RBQFetchedResultsController *)controller;

@end

#pragma mark - RBQFetchedResultsController

@interface RBQFetchedResultsController : NSObject

@property (nonatomic, readonly) RBQFetchRequest *fetchRequest;

@property (nonatomic, readonly) NSString *sectionNameKeyPath;

@property (nonatomic, weak) id <RBQFetchedResultsControllerDelegate> delegate;

@property (nonatomic, readonly) NSString *cacheName;

@property (nonatomic, readonly) RLMResults *fetchedObjects;

/*  Deletes the cached section information with the given name.
    
    If name is nil, deletes all cache files.
*/
+ (void)deleteCacheWithName:(NSString *)name;

/*  Caching is always used. Specify a name to manually delete later on
    
    If name is nil, a cache will be created with a name generated from
    the hash of the fetch request.
*/
- (id)initWithFetchRequest:(RBQFetchRequest *)fetchRequest
        sectionNameKeyPath:(NSString *)sectionNameKeyPath
                 cacheName:(NSString *)name;

- (id)initWithFetchRequest:(RBQFetchRequest *)fetchRequest
        sectionNameKeyPath:(NSString *)sectionNameKeyPath
        inMemoryRealmCache:(RLMRealm *)inMemoryRealm;

// Thread-safe
- (BOOL)performFetch;

// -----------------------------
// Accessing Section Information
// -----------------------------
- (NSInteger)numberOfRowsForSectionIndex:(NSInteger)index;

- (NSInteger)numberOfSections;

- (NSString *)titleForHeaderInSection:(NSInteger)section;

// ----------------------------
// Accessing Object Information
// ----------------------------

- (RBQSafeRealmObject *)safeObjectAtIndexPath:(NSIndexPath *)indexPath;

// Note: RLMObject returned is not thread-safe
- (id)objectAtIndexPath:(NSIndexPath *)indexPath;

- (id)objectInRealm:(RLMRealm *)realm
        atIndexPath:(NSIndexPath *)indexPath;

- (NSIndexPath *)indexPathForSafeObject:(RBQSafeRealmObject *)safeObject;

- (NSIndexPath *)indexPathForObject:(RLMObject *)object;

@end
