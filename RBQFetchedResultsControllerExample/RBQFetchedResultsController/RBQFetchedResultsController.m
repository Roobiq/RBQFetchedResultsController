//
//  RBQFetchedResultsController.m
//  RBQFetchedResultsControllerTest
//
//  Created by Lauren Smith on 1/2/15.
//  Copyright (c) 2015 Roobiq. All rights reserved.
//

#import "RBQFetchedResultsController.h"
#import "RBQFetchedResultsController_Private.h"


#import "RLMObject+Utilities.h"
#import "RBQRealmNotificationManager.h"
#import "RBQFetchedResultsControllerCacheObject.h"
#import "RBQSectionCacheObject.h"

@import UIKit;

#pragma mark - RBQFetchedResultsSectionInfo

@implementation RBQFetchedResultsSectionInfo
@synthesize name = _name;

+ (instancetype)createSectionWithName:(NSString *)sectionName
                   sectionNameKeyPath:(NSString *)sectionNameKeyPath
                         fetchRequest:(RBQFetchRequest *)fetchRequest
{
    RBQFetchedResultsSectionInfo *sectionInfo = [[RBQFetchedResultsSectionInfo alloc] init];
    sectionInfo->_name = sectionName;
    sectionInfo.sectionNameKeyPath = sectionNameKeyPath;
    sectionInfo.fetchRequest = fetchRequest;
    
    return sectionInfo;
}

- (RLMResults *)objects
{
    if (self.fetchRequest &&
        self.sectionNameKeyPath) {
        
        RLMResults *fetchResults = [RBQFetchedResultsController fetchResultsInRealm:self.fetchRequest.realm
                                                                    forFetchRequest:self.fetchRequest];
        
        return [fetchResults objectsWhere:@"%K == %@",
                self.sectionNameKeyPath,
                self.name];
    }
    
    return nil;
}

- (NSUInteger)numberOfObjects
{
    return [self objects].count;
}

@end

#pragma mark - RBQChangeSet

@implementation RBQChangeSet

@end

#pragma mark - RBQSectionChange

@implementation RBQSectionChange

@end

#pragma mark - RBQObjectChange

@implementation RBQObjectChange

+ (RBQObjectChange *)objectChangeWithCacheObject:(RBQFetchedResultsCacheObject *)cacheObject
                                       changeSet:(RBQChangeSet *)changeSet
{
    RBQObjectChange *objectChange = [[RBQObjectChange alloc] init];
    
    objectChange.previousCacheObject =
    [RBQFetchedResultsCacheObject objectInRealm:changeSet.cacheRealm
                                  forPrimaryKey:cacheObject.primaryKeyStringValue];
    
    RBQSectionCacheObject *oldSectionForObject = objectChange.previousCacheObject.section;
    
    // Get old indexPath if we can
    if (oldSectionForObject &&
        objectChange.previousCacheObject) {
        
        NSInteger oldSectionIndex = [changeSet.oldCacheSections indexOfObject:oldSectionForObject];
        
        NSInteger oldRowIndex = [oldSectionForObject.objects indexOfObject:objectChange.previousCacheObject];
        
        objectChange.previousIndexPath = [NSIndexPath indexPathForRow:oldRowIndex inSection:oldSectionIndex];
    }
    
    // Get new indexPath if we can
    RLMObject *updatedObject = [RBQFetchedResultsCacheObject objectForCacheObject:cacheObject
                                                                          inRealm:changeSet.realm];
    
    if (updatedObject) {
        NSInteger newAllObjectIndex = [changeSet.fetchResults indexOfObject:updatedObject];
        
        if (newAllObjectIndex != NSNotFound) {
            RBQSectionCacheObject *newSection = nil;
            
            NSInteger newSectionIndex = 0;
            
            for (RBQSectionCacheObject *section in changeSet.sortedNewCacheSections) {
                if (newAllObjectIndex >= section.firstObjectIndex) {
                    newSection = section;
                    
                    break;
                }
                
                newSectionIndex ++;
            }
            
            NSInteger newRowIndex = newAllObjectIndex - newSection.firstObjectIndex;
            
            objectChange.updatedCacheObject = cacheObject;
            objectChange.updatedIndexpath = [NSIndexPath indexPathForRow:newRowIndex inSection:newSectionIndex];
        }
    }
    
    return objectChange;
}

@end

#pragma mark - RBQFetchedResultsChanges

@implementation RBQFetchedResultsChanges

- (NSMutableArray *)sectionChanges
{
    if (!_sectionChanges) {
        _sectionChanges = @[].mutableCopy;
    }
    
    return _sectionChanges;
}

- (NSMutableArray *)deletedObjectChanges
{
    if (!_deletedObjectChanges) {
        _deletedObjectChanges = @[].mutableCopy;
    }
    
    return _deletedObjectChanges;
}

- (NSMutableArray *)insertedObjectChanges
{
    if (!_insertedObjectChanges) {
        _insertedObjectChanges = @[].mutableCopy;
    }
    
    return _insertedObjectChanges;
}

- (NSMutableArray *)movedObjectChanges
{
    if (!_movedObjectChanges) {
        _movedObjectChanges = @[].mutableCopy;
    }
    
    return _movedObjectChanges;
}

@end

#pragma mark - RBQFetchedResultsController

@implementation RBQFetchedResultsController
@synthesize cacheName = _cacheName;

#pragma mark - Public Class

+ (void)deleteCacheWithName:(NSString *)name
{
    RLMRealm *cacheRealm = [RBQFetchedResultsController realmForCacheName:name];
    
    [cacheRealm deleteAllObjects];
}

#pragma mark - Private Class

+ (RLMRealm *)realmForCacheName:(NSString *)cacheName
{
    return [RLMRealm realmWithPath:[RBQFetchedResultsController cachePathWithName:cacheName]];
}

+ (NSString *)cachePathWithName:(NSString *)name
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentPath = [paths objectAtIndex:0];
    BOOL isDir = NO;
    NSError *error = nil;
    
    NSString *cachePath = [documentPath stringByAppendingPathComponent:@"/RBQFetchedResultsControllerCache/"];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:cachePath isDirectory:&isDir] && isDir == NO) {
        [[NSFileManager defaultManager] createDirectoryAtPath:cachePath withIntermediateDirectories:NO attributes:nil error:&error];
    }
    
    NSString *fileName = [NSString stringWithFormat:@"%@.realm",name];
    
    cachePath = [cachePath stringByAppendingPathComponent:fileName];
    
    return cachePath;
}

+ (RLMResults *)fetchResultsInRealm:(RLMRealm *)realm
                    forFetchRequest:(RBQFetchRequest *)fetchRequest
{
    RLMResults *fetchResults = [NSClassFromString(fetchRequest.entityName) allObjectsInRealm:realm];
    
    // If we have a predicate use it
    if (fetchRequest.predicate) {
        fetchResults = [fetchResults objectsWithPredicate:fetchRequest.predicate];
    }
    
    // If we have sort descriptors then use them
    if (fetchRequest.sortDescriptors.count > 0) {
        fetchResults = [fetchResults sortedResultsUsingDescriptors:fetchRequest.sortDescriptors];
    }
    
    NSLog(@"Fetched %ld objects", (long)fetchResults.count);
    
    return fetchResults;
}

#pragma mark - Public Instance

- (id)initWithFetchRequest:(RBQFetchRequest *)fetchRequest
        sectionNameKeyPath:(NSString *)sectionNameKeyPath
                 cacheName:(NSString *)name
{
    self = [super init];
    
    if (self) {
        _cacheName = name;
        _fetchRequest = fetchRequest;
        _sectionNameKeyPath = sectionNameKeyPath;
        
        [self registerChangeNotification];
    }
    
    return self;
}

- (BOOL)performFetch
{
    if (self.fetchRequest) {
        
        if (self.cacheName) {
            
            [self createCacheWithRealm:[self cacheRealm]
                             cacheName:self.cacheName
                       forFetchRequest:self.fetchRequest
                    sectionNameKeyPath:self.sectionNameKeyPath];
        }
        else {
            [self createCacheWithRealm:[self cacheRealm]
                             cacheName:[self nameForFetchRequest:self.fetchRequest]
                       forFetchRequest:self.fetchRequest
                    sectionNameKeyPath:self.sectionNameKeyPath];
        }
        
        return YES;
    }
    
    @throw [NSException exceptionWithName:@"RBQException"
                                   reason:@"Unable to perform fetch; fetchRequest must be set."
                                 userInfo:nil];
    
    return NO;
}

- (RBQSafeRealmObject *)safeObjectAtIndexPath:(NSIndexPath *)indexPath
{
    RBQFetchedResultsControllerCacheObject *cache = [self cache];
    
    RBQSectionCacheObject *section = cache.sections[indexPath.section];
    
    RBQFetchedResultsCacheObject *cacheObject = section.objects[indexPath.row];
    
    RLMObject *object = [RBQFetchedResultsCacheObject objectForCacheObject:cacheObject
                                                                   inRealm:self.fetchRequest.realm];
    
    return [RBQSafeRealmObject safeObjectFromObject:object];
}

- (id)objectAtIndexPath:(NSIndexPath *)indexPath
{
    RBQFetchedResultsControllerCacheObject *cache = [self cache];
    
    RBQSectionCacheObject *section = cache.sections[indexPath.section];
    
    RBQFetchedResultsCacheObject *cacheObject = section.objects[indexPath.row];
    
    return [RBQFetchedResultsCacheObject objectForCacheObject:cacheObject
                                                      inRealm:self.fetchRequest.realm];
}

- (id)objectInRealm:(RLMRealm *)realm
        atIndexPath:(NSIndexPath *)indexPath
{
    RBQFetchedResultsControllerCacheObject *cache = [self cache];
    
    RBQSectionCacheObject *section = cache.sections[indexPath.section];
    
    RBQFetchedResultsCacheObject *cacheObject = section.objects[indexPath.row];
    
    return [RBQFetchedResultsCacheObject objectForCacheObject:cacheObject
                                                      inRealm:realm];
}

- (NSIndexPath *)indexPathForSafeObject:(RBQSafeRealmObject *)safeObject
{
    RLMRealm *realm = [self cacheRealm];
    
    RBQFetchedResultsControllerCacheObject *cache = [self cache];
    
    RBQFetchedResultsCacheObject *cacheObject =
    [RBQFetchedResultsCacheObject objectInRealm:realm forPrimaryKey:safeObject.primaryKeyValue];
    
    NSInteger sectionIndex = [cache.sections indexOfObject:cacheObject.section];
    NSInteger rowIndex = [cacheObject.section.objects indexOfObject:cacheObject];
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:rowIndex inSection:sectionIndex];
    
    return indexPath;
}

- (NSIndexPath *)indexPathForObject:(RLMObject *)object
{
    RBQFetchedResultsControllerCacheObject *cache = [self cache];
    
    RBQFetchedResultsCacheObject *cacheObject =
    [RBQFetchedResultsCacheObject cacheObjectInRealm:[self cacheRealm]
                                           forObject:object];
    
    NSInteger sectionIndex = [cache.sections indexOfObject:cacheObject.section];
    NSInteger rowIndex = [cacheObject.section.objects indexOfObject:cacheObject];
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:rowIndex inSection:sectionIndex];
    
    return indexPath;
}

- (NSInteger)numberOfRowsForSectionIndex:(NSInteger)index
{
    RBQFetchedResultsControllerCacheObject *cache = [self cache];
    
    RBQSectionCacheObject *section = cache.sections[index];
    
    return section.objects.count;
}

- (NSInteger)numberOfSections
{
    RBQFetchedResultsControllerCacheObject *cache = [self cache];
    
    return cache.sections.count;
}

- (NSString *)titleForHeaderInSection:(NSInteger)section
{
    RBQFetchedResultsControllerCacheObject *cache = [self cache];
    
    RBQSectionCacheObject *sectionInfo = cache.sections[section];
    
    return sectionInfo.name;
}

#pragma mark - Getters

- (RLMResults *)fetchedObjects
{
    if (self.fetchRequest) {
        return [RBQFetchedResultsController fetchResultsInRealm:self.fetchRequest.realm
                                                forFetchRequest:self.fetchRequest];
    }
    
    return nil;
}

#pragma mark - Private

- (void)registerChangeNotification
{
    // Start Notifications
    self.notificationToken = [[RBQRealmNotificationManager defaultManager] addNotificationBlock:
        ^(NSArray *addedSafeObjects,
          NSArray *deletedSafeObjects,
          NSArray *changedSafeObjects,
          RLMRealm *realm)
        {

            if ([self.delegate respondsToSelector:@selector(controllerWillChangeContent:)])
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.delegate controllerWillChangeContent:self];
                });
            }
            
            RBQChangeSet *changeSet = [self createChangeSetsWithAddedObjects:addedSafeObjects
                                                             deletedSafeObject:deletedSafeObjects
                                                            changedSafeObjects:changedSafeObjects
                                                                         realm:realm];
            
            if (!changeSet) {
                NSLog(@"No change objects or section changes found!");
                
                return;
            }
            
            [changeSet.cacheRealm beginWriteTransaction];
            
            // Create Change Object
            RBQFetchedResultsChanges *allChanges = [[RBQFetchedResultsChanges alloc] init];
            
            // ---------------
            // Section Changes
            // ---------------
            
            // Deleted Sections
            for (RBQSectionCacheObject *section in changeSet.deletedCacheSections) {
                
                NSInteger oldSectionIndex = [changeSet.oldCacheSections indexOfObject:section];
                
                if ([self.delegate
                     respondsToSelector:@selector(controller:didChangeSection:atIndex:forChangeType:)])
                {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        RBQFetchedResultsSectionInfo *sectionInfo =
                        [RBQFetchedResultsSectionInfo createSectionWithName:section.name
                                                         sectionNameKeyPath:self.sectionNameKeyPath
                                                               fetchRequest:self.fetchRequest];
                        
                        [self.delegate controller:self
                                 didChangeSection:sectionInfo
                                          atIndex:oldSectionIndex
                                    forChangeType:NSFetchedResultsChangeDelete];
                    });
                }
                
                // Create the section change object
                RBQSectionChange *sectionChange = [[RBQSectionChange alloc] init];
                sectionChange.previousIndex = @(oldSectionIndex);
                sectionChange.section = section;
                sectionChange.changeType = NSFetchedResultsChangeDelete;
                
                [allChanges.sectionChanges addObject:sectionChange];
            }
            
            // Inserted Sections
            for (RBQSectionCacheObject *section in changeSet.insertedCacheSections) {
                
                NSInteger newSectionIndex = [changeSet.sortedNewCacheSections indexOfObject:section];
                
                if ([self.delegate
                     respondsToSelector:@selector(controller:didChangeSection:atIndex:forChangeType:)])
                {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        RBQFetchedResultsSectionInfo *sectionInfo =
                        [RBQFetchedResultsSectionInfo createSectionWithName:section.name
                                                         sectionNameKeyPath:self.sectionNameKeyPath
                                                               fetchRequest:self.fetchRequest];
                        
                        [self.delegate controller:self
                                 didChangeSection:sectionInfo
                                          atIndex:newSectionIndex
                                    forChangeType:NSFetchedResultsChangeInsert];
                    });
                }
                
                // Create the section change object
                RBQSectionChange *sectionChange = [[RBQSectionChange alloc] init];
                sectionChange.updatedIndex = @(newSectionIndex);
                sectionChange.section = section;
                sectionChange.changeType = NSFetchedResultsChangeInsert;
                
                [allChanges.sectionChanges addObject:sectionChange];
            }
            
            // ---------------
            // Object Changes
            // ---------------
            NSUInteger index = 0;
            NSUInteger countChange = ABS(changeSet.fetchResults.count - changeSet.cache.objects.count);
            
            for (RBQFetchedResultsCacheObject *cacheObject in changeSet.cacheObjectsChangeSet) {
                
                RBQObjectChange *objectChange = [RBQObjectChange objectChangeWithCacheObject:cacheObject
                                                                                   changeSet:changeSet];
                
                // Deleted Objects
                if (!objectChange.updatedIndexpath &&
                    objectChange.previousIndexPath) {
                    
                    if ([self.delegate respondsToSelector:
                         @selector(controller:didChangeObject:atIndexPath:forChangeType:newIndexPath:)])
                    {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self.delegate controller:self
                                      didChangeObject:[changeSet.safeObjectsSet objectAtIndex:index]
                                          atIndexPath:objectChange.previousIndexPath
                                        forChangeType:NSFetchedResultsChangeDelete
                                         newIndexPath:nil];
                        });
                    }
                    
                    objectChange.changeType = NSFetchedResultsChangeDelete;
                    
                    [allChanges.deletedObjectChanges addObject:objectChange];
                }
                // Inserted Objects
                else if (objectChange.updatedIndexpath &&
                         !objectChange.previousIndexPath) {
                    
                    if ([self.delegate respondsToSelector:
                         @selector(controller:didChangeObject:atIndexPath:forChangeType:newIndexPath:)])
                    {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self.delegate controller:self
                                      didChangeObject:[changeSet.safeObjectsSet objectAtIndex:index]
                                          atIndexPath:nil
                                        forChangeType:NSFetchedResultsChangeInsert
                                         newIndexPath:objectChange.updatedIndexpath];
                        });
                    }
                    objectChange.changeType = NSFetchedResultsChangeInsert;
                    
                    [allChanges.insertedObjectChanges addObject:objectChange];
                }
                // Moved Objects
                // Compare the row changes to the count change
                // Fixes issue where we miss a move because indexes are now the same because of deletes/inserts
                else if ((objectChange.previousIndexPath.section == objectChange.updatedIndexpath.section) &&
                         (ABS(objectChange.previousIndexPath.row - objectChange.updatedIndexpath.row) != countChange)) {
                    
                    if ([self.delegate respondsToSelector:
                         @selector(controller:didChangeObject:atIndexPath:forChangeType:newIndexPath:)])
                    {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self.delegate controller:self
                                      didChangeObject:[changeSet.safeObjectsSet objectAtIndex:index]
                                          atIndexPath:objectChange.previousIndexPath
                                        forChangeType:NSFetchedResultsChangeMove
                                         newIndexPath:objectChange.updatedIndexpath];
                        });
                    }
                    
                    objectChange.changeType = NSFetchedResultsChangeMove;
                    
                    [allChanges.movedObjectChanges addObject:objectChange];
                }
                // Updated Objects
                else {
                    
                    if ([self.delegate respondsToSelector:
                         @selector(controller:didChangeObject:atIndexPath:forChangeType:newIndexPath:)])
                    {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self.delegate controller:self
                                      didChangeObject:[changeSet.safeObjectsSet objectAtIndex:index]
                                          atIndexPath:objectChange.updatedIndexpath
                                        forChangeType:NSFetchedResultsChangeUpdate
                                         newIndexPath:nil];
                        });
                    }
                }
                // Missing else: item wasn't there before or after, but was edited -- don't care
            }
            
            // Apple Section Changes To Cache
            for (RBQSectionChange *sectionChange in allChanges.sectionChanges) {
                if (sectionChange.changeType == NSFetchedResultsChangeDelete) {
                    // Remove the section from Realm cache
                    [changeSet.cache.sections removeObjectAtIndex:sectionChange.previousIndex.unsignedIntegerValue];
                }
                else if (sectionChange.changeType == NSFetchedResultsChangeInsert) {
                    // Add the section to the cache
                    [changeSet.cache.sections insertObject:sectionChange.section
                                                   atIndex:sectionChange.updatedIndex.unsignedIntegerValue];
                }
            }
            // Apple Object Changes To Cache (Must apply in correct order!)
            for (NSMutableArray *objectChanges in @[allChanges.deletedObjectChanges,
                                                    allChanges.insertedObjectChanges,
                                                    allChanges.movedObjectChanges]) {
                
                for (RBQObjectChange *objectChange in objectChanges) {
                    if (objectChange.changeType == NSFetchedResultsChangeDelete) {
                        // Remove the object
                        [changeSet.cacheRealm deleteObject:objectChange.previousCacheObject];
                    }
                    else if (objectChange.changeType == NSFetchedResultsChangeInsert) {
                        // Insert the object
                        [changeSet.cacheRealm addObject:objectChange.updatedCacheObject];

                        // Get the section and add it to it
                        RBQSectionCacheObject *section =
                        [RBQSectionCacheObject objectInRealm:changeSet.cacheRealm
                                               forPrimaryKey:objectChange.updatedCacheObject.sectionKeyPathValue];

                        [section.objects insertObject:objectChange.updatedCacheObject
                                              atIndex:objectChange.updatedIndexpath.row];
                        
                        objectChange.updatedCacheObject.section = section;
                    }
                    else if (objectChange.changeType == NSFetchedResultsChangeMove) {
                        // Delete to remove it from previous section
                        [changeSet.cacheRealm deleteObject:objectChange.previousCacheObject];

                        // Add it back in
                        [changeSet.cacheRealm addObject:objectChange.updatedCacheObject];

                        // Get the section and add it to it
                        RBQSectionCacheObject *section =
                        [RBQSectionCacheObject objectInRealm:changeSet.cacheRealm
                                               forPrimaryKey:objectChange.updatedCacheObject.sectionKeyPathValue];

                        [section.objects insertObject:objectChange.updatedCacheObject
                                              atIndex:objectChange.updatedIndexpath.row];
                        
                        objectChange.updatedCacheObject.section = section;
                    }
                }
            }
            
            [changeSet.cacheRealm commitWriteTransaction];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                NSLog(@"Added Safe Objects: %lu", (unsigned long)addedSafeObjects.count);
                NSLog(@"Deleted Safe Objects: %lu", (unsigned long)deletedSafeObjects.count);
                NSLog(@"Changed Safe Objects: %lu", (unsigned long)changedSafeObjects.count);
                
                if ([self.delegate respondsToSelector:@selector(controllerDidChangeContent:)]) {
                    [self.delegate controllerDidChangeContent:self];
                }
            });
    }];
}

// Create index backed by Realm
- (void)createCacheWithRealm:(RLMRealm *)cacheRealm
                   cacheName:(NSString *)cacheName
             forFetchRequest:(RBQFetchRequest *)fetchRequest
          sectionNameKeyPath:(NSString *)sectionNameKeyPath
{
    
    
    RLMResults *fetchResults = [RBQFetchedResultsController fetchResultsInRealm:fetchRequest.realm
                                                                forFetchRequest:fetchRequest];
    
    // Iterate over the results to create the section information
    NSString *currentSectionTitle = nil;
    
    // Check if we have a cache already
    RBQFetchedResultsControllerCacheObject *controllerCache =
    [RBQFetchedResultsControllerCacheObject objectInRealm:cacheRealm
                                            forPrimaryKey:cacheName];
    
    [cacheRealm beginWriteTransaction];
    
    if (controllerCache.fetchRequestHash != fetchRequest.hash ||
        controllerCache.objects.count != fetchResults.count) {
        
        [cacheRealm deleteAllObjects];
        
        controllerCache = nil;
    }
    
    if (!controllerCache) {
        
        controllerCache = [RBQFetchedResultsControllerCacheObject cacheWithName:cacheName
                                                               fetchRequestHash:fetchRequest.hash];
        
        RBQSectionCacheObject *section = nil;
        NSUInteger count = 0;
        
        for (RLMObject *object in fetchResults) {
            // Keep track of the count
            count ++;
            
            if (sectionNameKeyPath) {
                
                NSString *sectionTitle = [object valueForKey:sectionNameKeyPath];
                
                // New Section Found --> Process It
                if (![sectionTitle isEqualToString:currentSectionTitle]) {
                    
                    // If we already gathered up the section objects, then save them
                    if (section.objects.count > 0) {
                        
                        // Add the section to Realm
                        [cacheRealm addObject:section];
                        
                        // Add the section to the controller cache
                        [controllerCache.sections addObject:section];
                    }
                    
                    // Keep track of the section title so we create one section cache per value
                    currentSectionTitle = sectionTitle;
                    
                    // Reset the section object array
                    section = [RBQSectionCacheObject cacheWithName:currentSectionTitle];
                }
            }
            
            // Save the final section
            if (count == fetchResults.count && sectionNameKeyPath) {
                
                // Add the section to Realm
                [cacheRealm addObject:section];
                
                [controllerCache.sections addObject:section];
            }
            
            // Create the cache object
            RBQFetchedResultsCacheObject *cacheObject =
            [RBQFetchedResultsCacheObject createCacheObjectWithObject:object
                                                  sectionKeyPathValue:currentSectionTitle];
            
            cacheObject.section = section;
            
            if (section) {
                [section.objects addObject:cacheObject];
            }
            
            [controllerCache.objects addObject:cacheObject];
        }
        
        // Add cache to Realm
        [cacheRealm addObject:controllerCache];
    }
    
    [cacheRealm commitWriteTransaction];
}

#pragma mark - Create Internal Change Objects

- (RBQChangeSet *)createChangeSetsWithAddedObjects:(NSArray *)addedSafeObjects
                                  deletedSafeObject:(NSArray *)deletedSafeObjects
                                 changedSafeObjects:(NSArray *)changedSafeObjects
                                              realm:(RLMRealm *)realm
{
    // Make sure we have a fetch request
    if (!self.fetchRequest) {
        NSLog(@"FetchRequest is not set!");
        return  nil;
    }
    
    // Setup the change set
    RBQChangeSet *changeSet = [[RBQChangeSet alloc] init];
    
    changeSet.realm = realm;
    
    // Get the new list of safe fetch objects
    changeSet.fetchResults = [RBQFetchedResultsController fetchResultsInRealm:realm
                                                              forFetchRequest:self.fetchRequest];
    
    changeSet.cache = [self cache];
    
    changeSet.cacheRealm = [self cacheRealm];
    
    // Get Sections In Change Set
    NSMutableArray *cacheSectionsInChangeSet = @[].mutableCopy;
    NSMutableArray *cacheObjectsChangeSet = @[].mutableCopy;
    NSMutableArray *safeObjectSet = @[].mutableCopy;
    
    for (NSArray *changedObjects in @[changedSafeObjects, addedSafeObjects, deletedSafeObjects]) {
        for (RBQSafeRealmObject *safeObject in changedObjects) {
            
            // Check if this object is an entity we are tracking!
            if ([safeObject.className isEqualToString:self.fetchRequest.entityName]) {
                
                // Get the section titles in change set
                // Attempt to get the object from non-cache Realm
                RLMObject *object = [RBQSafeRealmObject objectInRealm:realm fromSafeObject:safeObject];
                
                NSString *sectionTitle = nil;
                
                if (object) {
                    sectionTitle = [object valueForKey:self.sectionNameKeyPath];
                }
                else {
                    RBQFetchedResultsCacheObject *oldCacheObject =
                    [RBQFetchedResultsCacheObject objectInRealm:changeSet.cacheRealm
                                                  forPrimaryKey:safeObject.primaryKeyValue];
                    
                    sectionTitle = oldCacheObject.section.name;
                }
                
                if (sectionTitle) {
                    RBQSectionCacheObject *section = [RBQSectionCacheObject objectInRealm:changeSet.cacheRealm
                                                                            forPrimaryKey:sectionTitle];
                    
                    if (!section) {
                        section = [RBQSectionCacheObject cacheWithName:sectionTitle];
                    }
                    
                    [cacheSectionsInChangeSet addObject:section];
                }
                
                // Get the cache object
                RBQFetchedResultsCacheObject *cacheObject =
                [RBQFetchedResultsCacheObject createCacheObjectWithSafeObject:safeObject
                                                          sectionKeyPathValue:sectionTitle];
                
                [safeObjectSet addObject:safeObject];
                
                [cacheObjectsChangeSet addObject:cacheObject];
            }
        }
    }
    
    if (cacheSectionsInChangeSet.count > 0 ||
        cacheObjectsChangeSet.count > 0) {
        
        
        changeSet.cacheSectionsChangeSet = cacheSectionsInChangeSet.copy;
        changeSet.cacheObjectsChangeSet = cacheObjectsChangeSet.copy;
        changeSet.safeObjectsSet = safeObjectSet.copy;
        
        [self updateChangeSetForSections:changeSet];
        
        return changeSet;
    }
    
    // Did not find anything
    return nil;
}

- (void)updateChangeSetForSections:(RBQChangeSet *)changeSet
{
    
    if (!changeSet.cache ||
        !changeSet.cacheSectionsChangeSet) {
        
        @throw [NSException exceptionWithName:@"RBQException"
                                       reason:@"Cache must be set!"
                                     userInfo:nil];
    }
    
    // Get Old Sections
    NSMutableArray *oldSections = @[].mutableCopy;
    
    for (RBQSectionCacheObject *section in changeSet.cache.sections) {
        [oldSections addObject:section];
    }
    
    // Combine Old With Change Set (without dupes!)
    NSMutableArray *oldAndChange = oldSections.mutableCopy;
    
    for (RBQSectionCacheObject *section in changeSet.cacheSectionsChangeSet) {
        if (![oldAndChange containsObject:section]) {
            [oldAndChange addObject:section];
        }
    }
    
    NSMutableArray *newSections = @[].mutableCopy;
    NSMutableArray *deletedSections = @[].mutableCopy;
    
    // Loop through to identify the new sections in fetchResults
    for (RBQSectionCacheObject *section in oldAndChange) {
        
        RLMResults *sectionResults = [changeSet.fetchResults objectsWhere:@"%K == %@",
                                      self.sectionNameKeyPath,
                                      section.name];
        
        if (sectionResults.count > 0) {
            RLMObject *firstObject = [sectionResults firstObject];
            NSInteger firstObjectIndex = [changeSet.fetchResults indexOfObject:firstObject];
            
            // Write change to object index to cache Realm
            [changeSet.cacheRealm beginWriteTransaction];
            
            section.firstObjectIndex = firstObjectIndex;
            
            [changeSet.cacheRealm commitWriteTransaction];
            
            [newSections addObject:section];
        }
        else {
            // Save any that are not found in results (but not dupes)
            if (![deletedSections containsObject:section]) {
                [deletedSections addObject:section];
            }
        }
    }
    
    // Now sort the sections
    NSSortDescriptor* sortByFirstIndex =
    [NSSortDescriptor sortDescriptorWithKey:@"firstObjectIndex" ascending:YES];
    [newSections sortUsingDescriptors:@[sortByFirstIndex]];
    
    // Find inserted sections
    NSMutableArray *insertedSections = newSections;
    // Remove the sections in new, to identify any deleted sections
    [insertedSections removeObjectsInArray:oldSections];
    
    // Save the section collections
    changeSet.oldCacheSections = oldSections.copy;
    changeSet.deletedCacheSections = deletedSections.copy;
    changeSet.insertedCacheSections = insertedSections.copy;
    changeSet.sortedNewCacheSections = newSections.copy;
}

#pragma mark - Helpers

/**
 Apparently iOS 7+ NSIndexPath's can sometimes be UIMutableIndexPaths:
 http://stackoverflow.com/questions/18919459/ios-7-beginupdates-endupdates-inconsistent/18920573#18920573
 
 This foils using them as dictionary keys since isEqual: fails between an equivalent NSIndexPath and
 UIMutableIndexPath.
 */
- (NSIndexPath *)keyForIndexPath:(NSIndexPath *)indexPath
{
    if ([indexPath class] == [NSIndexPath class]) {
        return indexPath;
    }
    return [NSIndexPath indexPathForRow:indexPath.row inSection:indexPath.section];
}

- (RLMRealm *)cacheRealm
{
    if (self.cacheName) {
        return [RBQFetchedResultsController realmForCacheName:self.cacheName];
    }
    else {
        return [RBQFetchedResultsController realmForCacheName:[self nameForFetchRequest:self.fetchRequest]];
    }
    
    return nil;
}

- (RBQFetchedResultsControllerCacheObject *)cache
{
    if (self.cacheName) {
        
        return [RBQFetchedResultsControllerCacheObject objectInRealm:[self cacheRealm]
                                                       forPrimaryKey:self.cacheName];
    }
    else {
        return [RBQFetchedResultsControllerCacheObject objectInRealm:[self cacheRealm]
                                                       forPrimaryKey:[self nameForFetchRequest:self.fetchRequest]];
    }
    
    return nil;
}

- (NSString *)nameForFetchRequest:(RBQFetchRequest *)fetchRequest
{
    return [NSString stringWithFormat:@"%lu-cache",(unsigned long)fetchRequest.hash];
}

@end
