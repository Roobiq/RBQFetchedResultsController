//
//  RBQFetchedResultsController.h
//  RBQFetchedResultsControllerTest
//
//  Created by Adam Fish on 1/2/15.
//  Copyright (c) 2015 Roobiq. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RBQFetchRequest.h"
#import "RBQSafeRealmObject.h"

@import CoreData;

@class RBQFetchedResultsController;

#pragma mark - RBQFetchedResultsSectionInfo

/**
 *  This class is used by the RBQFetchedResultsController to pass along section info.
 */
@interface RBQFetchedResultsSectionInfo : NSObject

/**
 *  The number of objects in the section.
 */
@property (nonatomic, readonly) NSUInteger numberOfObjects;

/**
 *  The objects in the section (generated on-demand and not thread-safe).
 */
@property (nonatomic, readonly, nonnull) id<RLMCollection> objects;

/**
 *  The name of the section.
 */
@property (nonatomic, readonly, nonnull) NSString *name;

@end

#pragma mark - RBQFetchedResultsControllerDelegate

/**
 *  Delegate to pass along the changes identified by the RBQFetchedResultsController.
 */
@protocol RBQFetchedResultsControllerDelegate <NSObject>


/**
 *  Indicates that the controller has started identifying changes.
 *
 *  @param controller controller instance that noticed the change on its fetched objects
 */
- (void)controllerWillChangeContent:(nonnull RBQFetchedResultsController *)controller;

/**
 *  Notifies the delegate that a fetched object has been changed due to an add, remove, move, or update. Enables RBQFetchedResultsController change tracking.
 *
 *  Changes are reported with the following heuristics:
 *
 *  On add and remove operations, only the added/removed object is reported. It’s assumed that all objects that come after the affected object are also moved, but these moves are not reported.
 *
 *  A move is reported when the changed attribute on the object is one of the sort descriptors used in the fetch request. An update of the object is assumed in this case, but no separate update message is sent to the delegate.
 *
 *  An update is reported when an object’s state changes, but the changed attributes aren’t part of the sort keys.
 *
 *  @param controller controller instance that noticed the change on its fetched objects
 *  @param anObject changed object represented as a RBQSafeRealmObject for thread safety
 *  @param indexPath indexPath of changed object (nil for inserts)
 *  @param type indicates if the change was an insert, delete, move, or update
 *  @param newIndexPath the destination path for inserted or moved objects, nil otherwise
 */

- (void)controller:(nonnull RBQFetchedResultsController *)controller
   didChangeObject:(nonnull RBQSafeRealmObject *)anObject
       atIndexPath:(nullable NSIndexPath *)indexPath
     forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(nullable NSIndexPath *)newIndexPath;

/**
 *  The fetched results controller reports changes to its section before changes to the fetched result objects.
 *
 *  @param controller   controller controller instance that noticed the change on its fetched objects
 *  @param section      changed section represented as a RBQFetchedResultsSectionInfo object
 *  @param sectionIndex the section index of the changed section
 *  @param type         indicates if the change was an insert or delete
 */
- (void)controller:(nonnull RBQFetchedResultsController *)controller
  didChangeSection:(nonnull RBQFetchedResultsSectionInfo *)section
           atIndex:(NSUInteger)sectionIndex
     forChangeType:(NSFetchedResultsChangeType)type;

/**
 *  This method is called at the end of processing changes by the controller
 *
 *  @param controller controller instance that noticed the change on its fetched objects
 */
- (void)controllerDidChangeContent:(nonnull RBQFetchedResultsController *)controller;

@optional

/**
 *  This method is called before the controller performs the fetch.
 *
 *  @param controller controller instance that will perform the fetch
 */
- (void)controllerWillPerformFetch:(nonnull RBQFetchedResultsController *)controller;

/**
 *  This method is called after the controller successfully fetches objects. It will not be called if the fetchRequest is nil.
 *
 *  @param controller controller instance that performed the fetch
 */
- (void)controllerDidPerformFetch:(nonnull RBQFetchedResultsController *)controller;

@end

#pragma mark - RBQFetchedResultsController

/**
 *  The class is used to monitor changes from a RBQRealmNotificationManager to convert these changes into specific index path or section index changes. Typically this is used to back a UITableView and support animations when items are inserted, deleted, or changed.
 */
@interface RBQFetchedResultsController : NSObject

/**
 *  The fetch request for the controller
 */
@property (nonatomic, readonly, nonnull) RBQFetchRequest *fetchRequest;

/**
 *  The section name key path used to create the sections. Can be nil if no sections.
 */
@property (nonatomic, readonly, nullable) NSString *sectionNameKeyPath;

/**
 *  The delegate to pass the index path and section changes to.
 */
@property (nonatomic, weak, nullable) id <RBQFetchedResultsControllerDelegate> delegate;

/**
 *  The name of the cache used internally to represent the tableview structure.
 */
@property (nonatomic, readonly, nullable) NSString *cacheName;

/**
 *  All the objects that match the fetch request.
 */
@property (nonatomic, readonly, nonnull) id<RLMCollection> fetchedObjects;

/**
 *  Returns all the section titles if using a section name key path
 */
@property(nonatomic, readonly, nullable) NSArray <NSString *> *sectionIndexTitles;

/**
 *  Deletes the cached section information with the given name
 *
 *  If name is not nil, then the cache will be cleaned, but not deleted from disk. 
 *
 *  If name is nil, then all caches will be deleted by removing the files from disk.
 *
 *  @warning  If clearing all caches (name is nil), it is recommended to do this in didFinishLaunchingWithOptions: in AppDelegate because RLMRealm files cannot be deleted from disk safely, if there are strong references to them.
 *
 *  @param name The name of the cache file to delete. If name is nil, deletes all cache files.
 */
+ (void)deleteCacheWithName:(nullable NSString *)name;

/**
 *  Retrieves all the paths for the Realm files being used as FRC caches on disk.
 *
 *  The typical use case for this method is to use the paths to perform migrations in AppDelegate. The FRC cache files need to be migrated along with your other Realm files because by default Realm includes all of the properties defined in your model in all Realm files. Thus the FRC cache files will throw an exception if they are not migrated. Call setSchemaVersion:forRealmAtPath:withMigrationBlock: for each path returned in the array.
 *
 *  @return NSArray of NSStrings representing the paths on disk for all FRC cache Realm files
 */
+ (nonnull NSArray *)allCacheRealmPaths;

/**
 *  Constructor method to initialize the controller
 *
 *  @warning Specify a cache name if deletion of the cache later on is necessary
 *
 *  @param fetchRequest       the RBQFetchRequest for the controller
 *  @param sectionNameKeyPath A key path on result objects that returns the section name. Pass nil to indicate that the controller should generate a single section. If this key path is not the same as that specified by the first sort descriptor in fetchRequest, they must generate the same relative orderings.
 *  @param name               the cache name (if nil, cache will not be persisted and built using an in-memory Realm)
 *
 *  @return A new instance of RBQFetchedResultsController
 */
- (nonnull id)initWithFetchRequest:(nonnull RBQFetchRequest *)fetchRequest
                sectionNameKeyPath:(nullable NSString *)sectionNameKeyPath
                         cacheName:(nullable NSString *)name;

/**
 *  Method to tell the controller to perform the fetch
 *
 *  @return Indicates if the fetch was successful
 */
- (BOOL)performFetch;

/**
 *  Call this method to force the cache to be rebuilt. 
 *
 *  A potential use case would be to call this in a @catch after trying to call endUpdates for the table view. If an exception is thrown, then the cache will be rebuilt and you can call reloadData on the table view.
 */
- (void)reset;

/**
 *  Method to retrieve the number of rows for a given section index
 *
 *  @param index section index
 *
 *  @return number of rows in the section
 */
- (NSInteger)numberOfRowsForSectionIndex:(NSInteger)index;

/**
 *  Method to retrieve the number of sections represented by the fetch request
 *
 *  @return number of sections
 */
- (NSInteger)numberOfSections;

/**
 *  Method to retrieve the title for a given section index
 *
 *  @param section section index
 *
 *  @return The title of the section
 */
- (nonnull NSString *)titleForHeaderInSection:(NSInteger)section;

/**
 *  Method to retrieve the section index given a section name
 *
 *  @warning Returns NSNotFound if there is not a section with the given name
 *
 *  @param sectionName the name of the section
 *
 *  @return the index of the section (returns NSNotFound if no section with the given name)
 */
- (NSUInteger)sectionIndexForSectionName:(nonnull NSString *)sectionName;

/**
 *  Retrieve the RBQSafeRealmObject for a given index path
 *
 *  @param indexPath the index path of the object
 *
 *  @return RBQSafeRealmObject
 */
- (nullable RBQSafeRealmObject *)safeObjectAtIndexPath:(nonnull NSIndexPath *)indexPath;

/**
 *  Retrieve the RLMObject for a given index path
 *  
 *  @warning Returned object is not thread-safe.
 *
 *  @param indexPath the index path of the object
 *
 *  @return RLMObject
 */
- (nullable id)objectAtIndexPath:(nonnull NSIndexPath *)indexPath;

/**
 *  Retrieve the index path for a safe object in the fetch request
 *
 *  @param safeObject RBQSafeRealmObject
 *
 *  @return index path of the object
 */
- (nullable NSIndexPath *)indexPathForSafeObject:(nonnull RBQSafeRealmObject *)safeObject;

/**
 *  Retrieve the index path for a RLMObject in the fetch request
 *
 *  @param object RLMObject
 *
 *  @return index path of the object
 */
- (nullable NSIndexPath *)indexPathForObject:(nonnull RLMObjectBase *)object;

/**
 *  Convenience method to safely update the fetch request for an existing RBQFetchResultsController
 *
 *  @param fetchRequest       a new instance of RBQFetchRequest
 *  @param sectionNameKeyPath the section name key path for this fetch request (if nil, no sections will be shown)
 *  @param performFetch       indicates whether you want to immediately performFetch using the new fetch request to rebuild the cache
 */
- (void)updateFetchRequest:(nonnull RBQFetchRequest *)fetchRequest
        sectionNameKeyPath:(nullable NSString *)sectionNameKeyPath
            andPerformFetch:(BOOL)performFetch;

@end
