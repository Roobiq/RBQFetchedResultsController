//
//  RBQFetchedResultsController.m
//  RBQFetchedResultsControllerTest
//
//  Created by Lauren Smith on 1/2/15.
//  Copyright (c) 2015 Roobiq. All rights reserved.
//

#import "RBQFetchedResultsController.h"
#import "RBQRealmNotificationManager.h"
#import "RBQFetchedResultsControllerCacheObject.h"
#import "RBQSectionCacheObject.h"

#import <objc/message.h>

@import UIKit;

#pragma mark - RBQFetchedResultsObject

// Object representing all of the various structures needed
@interface RBQFetchedResultsObject : NSObject <NSCopying>

@property (strong, nonatomic) NSArray *fetchedObjects;
@property (strong, nonatomic) NSArray *sections;
@property (strong, nonatomic) NSDictionary *indexPathKeyMap;
@property (strong, nonatomic) NSDictionary *objectKeyMap;

@end

@implementation RBQFetchedResultsObject

#pragma mark - <NSCopying>

- (id)copyWithZone:(NSZone *)zone
{
    RBQFetchedResultsObject *object = [[RBQFetchedResultsObject allocWithZone:zone] init];
    object->_fetchedObjects = _fetchedObjects;
    object->_sections = _sections;
    object->_indexPathKeyMap = _indexPathKeyMap;
    object->_objectKeyMap = _objectKeyMap;
    
    return object;
}

@end

@interface RBQFetchedResultsController ()

@property (strong, nonatomic) RBQNotificationToken *notificationToken;
@property (strong, nonatomic) RBQFetchedResultsObject *fetchedResultsObject;

@end

#pragma mark - RBQFetchedResultsController

@implementation RBQFetchedResultsController
@synthesize cacheName = _cacheName;

#pragma mark - Public Class

+ (void)deleteCacheWithName:(NSString *)name
{
//    RLMRealm *realm = [RLMRealm realmWithPath:[RBQFetchedResultsController cachePath]];
//    
//    if (name) {
//        RBQFetchedResultsControllerCacheObject *cache = [RBQFetchedResultsControllerCacheObject objectInRealm:realm
//                                                                                                forPrimaryKey:name];
//        
//        if (cache) {
//            [realm deleteObject:cache];
//        }
//    }
//    else {
//        [realm deleteAllObjects];
//    }
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
            
            [self createCacheWithRealm:[self realmForCache]
                             cacheName:self.cacheName
                       forFetchRequest:self.fetchRequest
                    sectionNameKeyPath:self.sectionNameKeyPath];
        }
        else {
            [self createCacheWithRealm:[self realmForCache]
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
    
    RLMObject *object = [self objectForCacheObject:cacheObject inRealm:self.fetchRequest.realm];
    
    return [RBQSafeRealmObject safeObjectFromObject:object];
}

- (id)objectAtIndexPath:(NSIndexPath *)indexPath
{
    RBQFetchedResultsControllerCacheObject *cache = [self cache];
    
    RBQSectionCacheObject *section = cache.sections[indexPath.section];
    
    RBQFetchedResultsCacheObject *cacheObject = section.objects[indexPath.row];
    
    return [self objectForCacheObject:cacheObject inRealm:self.fetchRequest.realm];
}

- (id)objectInRealm:(RLMRealm *)realm
        atIndexPath:(NSIndexPath *)indexPath
{
    RBQFetchedResultsControllerCacheObject *cache = [self cache];
    
    RBQSectionCacheObject *section = cache.sections[indexPath.section];
    
    RBQFetchedResultsCacheObject *cacheObject = section.objects[indexPath.row];
    
    return [self objectForCacheObject:cacheObject inRealm:realm];
}

- (NSIndexPath *)indexPathForSafeObject:(RBQSafeRealmObject *)safeObject
{
    RLMRealm *realm = [self realmForCache];
    
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
    
    RBQFetchedResultsCacheObject *cacheObject = [self cacheObjectForObject:object];
    
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
            // Get the new list of safe fetch objects
            RLMResults *fetchResults = [self fetchResultsInRealm:realm
                                                 forFetchRequest:self.fetchRequest];
            
            RBQFetchedResultsControllerCacheObject *cache = [self cache];
            
            RLMRealm *cacheRealm = [self realmForCache];
            
            if ([self.delegate respondsToSelector:@selector(controllerWillChangeContent:)])
            {
                [self runBlockOnMainThread:^(){
                    [self.delegate controllerWillChangeContent:self];
                }];
            }
            
            [cacheRealm beginWriteTransaction];
            
            // Get Sections In Change Set
            NSMutableArray *sectionTitlesInChangeSet = @[].mutableCopy;
            NSMutableArray *cacheObjectsInChangeSet = @[].mutableCopy;
            
            for (NSArray *changedObjects in @[changedSafeObjects, addedSafeObjects, deletedSafeObjects]) {
                for (RBQSafeRealmObject *safeObject in changedObjects) {
                    
                    RLMObject *object = [RBQSafeRealmObject objectInRealm:realm fromSafeObject:safeObject];
                    
                    NSString *sectionTitle = nil;
                    
                    if (object) {
                        sectionTitle = [object valueForKey:self.sectionNameKeyPath];
                    }
                    else {
                        RBQFetchedResultsCacheObject *oldCacheObject =
                        [RBQFetchedResultsCacheObject objectInRealm:cacheRealm
                                                      forPrimaryKey:safeObject.primaryKeyValue];
                        
                        sectionTitle = oldCacheObject.section.name;
                    }
                    
                    [sectionTitlesInChangeSet addObject:sectionTitle];
                    
                    RBQFetchedResultsCacheObject *cacheObject = [RBQFetchedResultsCacheObject cacheObjectWithPrimaryKeyValue:safeObject.primaryKeyValue primaryKeyType:safeObject.primaryKeyProperty.type sectionKeyPathValue:sectionTitle];
                    
                    [cacheObjectsInChangeSet addObject:cacheObject];
                }
            }
            
            // Get Old Sections
            NSMutableArray *oldSections = @[].mutableCopy;
            NSMutableArray *oldSectionTitles = @[].mutableCopy;
            
            for (RBQSectionCacheObject *section in cache.sections) {
                [oldSections addObject:section];
                [oldSectionTitles addObject:section.name];
            }
            
            // Combine Old With Change Set (without dupes!)
            NSMutableArray *oldAndChange = oldSectionTitles.mutableCopy;
            
            for (NSString *sectionTitle in sectionTitlesInChangeSet) {
                if (![oldAndChange containsObject:sectionTitle]) {
                    [oldAndChange addObject:sectionTitle];
                }
            }
            
            NSMutableArray *newSections = @[].mutableCopy;
            NSMutableArray *newSectionTitles = @[].mutableCopy;
            NSMutableArray *deletedSectionTitles = @[].mutableCopy;
            
            // Loop through to identify the new sections in fetchResults
            for (NSString *sectionTitle in oldAndChange) {
                
                RLMResults *sectionResults =
                [fetchResults objectsWhere:@"%K == %@",self.sectionNameKeyPath,sectionTitle];
                
                if (sectionResults.count > 0) {
                    RLMObject *firstObject = [sectionResults firstObject];
                    NSInteger firstObjectIndex = [fetchResults indexOfObject:firstObject];
                    
                    RBQSectionCacheObject *section = [RBQSectionCacheObject cacheWithName:sectionTitle];
                    section.firstObjectIndex = firstObjectIndex;
                    
                    [newSections addObject:section];
                    [newSectionTitles addObject:sectionTitle];
                }
                else {
                    // Save any that are not found in results (but not dupes)
                    if (![deletedSectionTitles containsObject:sectionTitle]) {
                        [deletedSectionTitles addObject:sectionTitle];
                    }
                }
            }
            
            // Now sort the sections
            NSSortDescriptor* sortByFirstIndex =
            [NSSortDescriptor sortDescriptorWithKey:@"firstObjectIndex" ascending:YES];
            [newSections sortUsingDescriptors:@[sortByFirstIndex]];
            
            // We now have the sorted section list!
            NSArray *sortedSections = newSections.copy;
            
            NSMutableArray *sortedSectionTitles = @[].mutableCopy;
            
            for (RBQSectionCacheObject *section in sortedSections) {
                [sortedSectionTitles addObject:section.name];
            }
            
            // Process Deleted Sections
            for (NSString *sectionTitle in deletedSectionTitles) {
                
                NSInteger oldSectionIndex = NSIntegerMax;
                
                NSInteger index = 0;
                
                for (NSString *oldSectionTitle in oldSectionTitles) {
                    if ([oldSectionTitle isEqualToString:sectionTitle]) {
                        oldSectionIndex = index;
                        
                        break;
                    }
                    index ++;
                }
                
                if ([self.delegate
                     respondsToSelector:@selector(controller:didChangeSection:atIndex:forChangeType:)])
                {
                    [self runBlockOnMainThread:^(){
                        [self.delegate controller:self
                                 didChangeSection:nil
                                          atIndex:oldSectionIndex
                                    forChangeType:NSFetchedResultsChangeDelete];
                    }];
                }
                
                // Remove the section from Realm cache
                [cache.sections removeObjectAtIndex:oldSectionIndex];
            }
            
            // Find inserted sections
            NSMutableArray *insertedSectionTitles = newSectionTitles;
            // Remove the sections in new, to identify any deleted sections
            [insertedSectionTitles removeObjectsInArray:oldSectionTitles];
            
            // Process Inserted Sections
            for (NSString *sectionTitle in insertedSectionTitles) {
                NSInteger newSectionIndex = NSIntegerMax;
                
                NSInteger index = 0;
                RBQSectionCacheObject *newSection = nil;
                
                for (RBQSectionCacheObject *section in sortedSections) {
                    if ([section.name isEqualToString:sectionTitle]) {
                        newSectionIndex = index;
                        newSection = section;
                        break;
                    }
                    index ++;
                }
                
                if ([self.delegate
                     respondsToSelector:@selector(controller:didChangeSection:atIndex:forChangeType:)])
                {
                    [self runBlockOnMainThread:^(){
                        [self.delegate controller:self
                                 didChangeSection:nil
                                          atIndex:newSectionIndex
                                    forChangeType:NSFetchedResultsChangeInsert];
                    }];
                }
                
                // Add the section to the cache
                RBQSectionCacheObject *section = [RBQSectionCacheObject objectInRealm:cacheRealm
                                                                        forPrimaryKey:sectionTitle];
                if (section) {
                    [cache.sections insertObject:section atIndex:newSectionIndex];
                }
                else {
                    [cache.sections insertObject:newSection atIndex:newSectionIndex];
                }
            }
            
            // -------------------------
            // Now For The Object Changes
            // -------------------------
            
            for (RBQFetchedResultsCacheObject *cacheObject in cacheObjectsInChangeSet) {
                
                RBQFetchedResultsCacheObject *oldCacheObject =
                [RBQFetchedResultsCacheObject objectInRealm:cacheRealm
                                              forPrimaryKey:cacheObject.primaryKeyStringValue];
                
                RBQSectionCacheObject *oldSectionForObject = oldCacheObject.section;
                
                NSIndexPath *oldIndexPath = nil;
                NSIndexPath *newIndexPath = nil;
                
                if (oldSectionForObject &&
                    oldCacheObject) {
                    
                    NSInteger oldSectionIndex = NSIntegerMax;
                    
                    NSInteger index = 0;
                    
                    for (NSString *oldSectionTitle in oldSectionTitles) {
                        if ([oldSectionTitle isEqualToString:oldSectionForObject.name]) {
                            oldSectionIndex = index;
                            
                            break;
                        }
                        index ++;
                    }
                    
                    NSInteger oldRowIndex = [oldSectionForObject.objects indexOfObject:oldCacheObject];
                    
                    oldIndexPath = [NSIndexPath indexPathForRow:oldRowIndex inSection:oldSectionIndex];
                }
                
                RLMObject *newObject = [self objectForCacheObject:cacheObject inRealm:realm];
                
                if (newObject) {
                    NSInteger newAllObjectIndex = [fetchResults indexOfObject:newObject];
                    
                    if (newAllObjectIndex != NSNotFound) {
                        RBQSectionCacheObject *newSection = nil;
                        
                        for (RBQSectionCacheObject *section in sortedSections) {
                            if (newAllObjectIndex >= section.firstObjectIndex) {
                                newSection = section;
                                
                                break;
                            }
                        }
                        
                        NSInteger newSectionIndex = [sortedSectionTitles indexOfObject:newSection.name];
                        
                        NSInteger newRowIndex = newAllObjectIndex - newSection.firstObjectIndex;
                        
                        newIndexPath = [NSIndexPath indexPathForRow:newRowIndex inSection:newSectionIndex];
                    }
                }
                
                // Item was removed from change
                if (!newIndexPath && oldIndexPath) {
                    
                    if ([self.delegate respondsToSelector:
                         @selector(controller:didChangeObject:atIndexPath:forChangeType:newIndexPath:)])
                    {
                        [self runBlockOnMainThread:^(){
                            [self.delegate controller:self
                                      didChangeObject:nil
                                          atIndexPath:oldIndexPath
                                        forChangeType:NSFetchedResultsChangeDelete
                                         newIndexPath:nil];
                        }];
                    }
                    
                    // Remove the object
                    [cacheRealm deleteObject:oldCacheObject];
                }
                // Item was inserted from change
                else if (newIndexPath && !oldIndexPath) {
                    
                    if ([self.delegate respondsToSelector:
                         @selector(controller:didChangeObject:atIndexPath:forChangeType:newIndexPath:)])
                    {
                        [self runBlockOnMainThread:^(){
                            [self.delegate controller:self
                                      didChangeObject:nil
                                          atIndexPath:nil
                                        forChangeType:NSFetchedResultsChangeInsert
                                         newIndexPath:newIndexPath];
                        }];
                    }
                    
                    [cacheRealm addObject:cacheObject];
                    
                    // Get the section and add it to it
                    RBQSectionCacheObject *section =
                    [RBQSectionCacheObject objectInRealm:cacheRealm
                                           forPrimaryKey:cacheObject.sectionKeyPathValue];
                    
                    [section.objects insertObject:cacheObject atIndex:newIndexPath.row];
                    
                    cacheObject.section = section;
                }
                // Item was moved from change
                else if ([newIndexPath compare:oldIndexPath] != NSOrderedSame) {
                    
                    if ([self.delegate respondsToSelector:
                         @selector(controller:didChangeObject:atIndexPath:forChangeType:newIndexPath:)])
                    {
                        [self runBlockOnMainThread:^(){
                            [self.delegate controller:self
                                      didChangeObject:nil
                                          atIndexPath:oldIndexPath
                                        forChangeType:NSFetchedResultsChangeMove
                                         newIndexPath:newIndexPath];
                        }];
                    }
                    
                    // Delete to remove it from previous section
                    [cacheRealm deleteObject:oldCacheObject];
                    
                    // Add it back in
                    [cacheRealm addObject:cacheObject];
                    
                    // Get the section and add it to it
                    RBQSectionCacheObject *section =
                    [RBQSectionCacheObject objectInRealm:cacheRealm
                                           forPrimaryKey:cacheObject.sectionKeyPathValue];
                    
                    [section.objects insertObject:cacheObject atIndex:newIndexPath.row];
                    
                    cacheObject.section = section;
                }
                // Item updated -- may have to redraw
                else if ([newIndexPath compare:oldIndexPath] == NSOrderedSame) {
                    
                    if ([self.delegate respondsToSelector:
                         @selector(controller:didChangeObject:atIndexPath:forChangeType:newIndexPath:)])
                    {
                        [self runBlockOnMainThread:^(){
                            [self.delegate controller:self
                                      didChangeObject:nil
                                          atIndexPath:newIndexPath
                                        forChangeType:NSFetchedResultsChangeUpdate
                                         newIndexPath:nil];
                        }];
                    }
                }
                // Missing else: item wasn't there before or after, but was edited -- don't care
            }
            
            [cacheRealm commitWriteTransaction];
            
            [self runBlockOnMainThread:^(){
                NSLog(@"Added Safe Objects: %lu", (unsigned long)addedSafeObjects.count);
                NSLog(@"Deleted Safe Objects: %lu", (unsigned long)deletedSafeObjects.count);
                NSLog(@"Changed Safe Objects: %lu", (unsigned long)changedSafeObjects.count);
                
                if ([self.delegate respondsToSelector:@selector(controllerDidChangeContent:)]) {
                    [self.delegate controllerDidChangeContent:self];
                }
            }];
    }];
}

- (RLMResults *)fetchResultsInRealm:(RLMRealm *)realm
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

// Create index backed by Realm
- (void)createCacheWithRealm:(RLMRealm *)cacheRealm
                   cacheName:(NSString *)cacheName
             forFetchRequest:(RBQFetchRequest *)fetchRequest
          sectionNameKeyPath:(NSString *)sectionNameKeyPath
{
    
    
    RLMResults *fetchResults = [self fetchResultsInRealm:fetchRequest.realm
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
            id primaryKeyValue = [RBQSafeRealmObject primaryKeyValueForObject:object];
            
            RBQFetchedResultsCacheObject *cacheObject =
            [RBQFetchedResultsCacheObject cacheObjectWithPrimaryKeyValue:primaryKeyValue
                                                          primaryKeyType:object.objectSchema.primaryKeyProperty.type sectionKeyPathValue:currentSectionTitle];
            
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

- (NSArray *)sectionTitlesFromFetchResults:(NSArray *)fetchResults
                        sectionNameKeyPath:(NSString *)sectionNameKeyPath
{
    if (fetchResults) {
        NSMutableArray *sectionTitles = @[].mutableCopy;
        
        for (RBQSafeRealmObject *safeObject in fetchResults) {
            RLMObject *object = [safeObject RLMObject];
            
            NSString *sectionTitle = [object valueForKey:sectionNameKeyPath];
            
            if (![sectionTitles containsObject:sectionTitle]) {
                [sectionTitles addObject:sectionTitle];
            }
        }
        
        return sectionTitles.copy;
    }

    return nil;
}

- (RBQFetchedResultsCacheObject *)cacheObjectForObject:(RLMObject *)object
{
    if (object) {
        NSString *primaryKeyValue = (NSString *)[RBQSafeRealmObject primaryKeyValueForObject:object];
        
        if (object.objectSchema.primaryKeyProperty.type == RLMPropertyTypeString) {
            
            return [RBQFetchedResultsCacheObject objectInRealm:[self realmForCache]
                                                 forPrimaryKey:primaryKeyValue];
        }
        else {
            NSNumber *numberFromString = @(primaryKeyValue.integerValue);
            
            return [RBQFetchedResultsCacheObject objectInRealm:[self realmForCache]
                                                 forPrimaryKey:(id)numberFromString];
        }
    }
    
    return nil;
}

- (RLMObject *)objectForCacheObject:(RBQFetchedResultsCacheObject *)cacheObject
                            inRealm:(RLMRealm *)realm
{
    if (cacheObject.primaryKeyType == RLMPropertyTypeString) {
        
        return [NSClassFromString(self.fetchRequest.entityName) objectInRealm:realm
                                                                forPrimaryKey:cacheObject.primaryKeyStringValue];
    }
    else {
        NSNumber *numberFromString = @(cacheObject.primaryKeyStringValue.integerValue);
        
        return [NSClassFromString(self.fetchRequest.entityName) objectInRealm:realm
                                                                forPrimaryKey:(id)numberFromString];
    }
}

- (void)runBlockOnMainThread:(void(^)())block
{
    if ([NSThread isMainThread]) {
        block();
    }
    else {
        dispatch_async(dispatch_get_main_queue(), ^{
            block();
        });
    }
}

#pragma mark - Utilities

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

- (RLMRealm *)realmForCache
{
    if (self.cacheName) {
        return [self realmForCacheName:self.cacheName];
    }
    else {
        return [self realmForCacheName:[self nameForFetchRequest:self.fetchRequest]];
    }
    
    return nil;
}

- (RLMRealm *)realmForCacheName:(NSString *)cacheName
{
    return [RLMRealm realmWithPath:[self cachePathWithName:cacheName]];
}

- (RBQFetchedResultsControllerCacheObject *)cache
{
    if (self.cacheName) {
        
        return [RBQFetchedResultsControllerCacheObject objectInRealm:[self realmForCache]
                                                       forPrimaryKey:self.cacheName];
    }
    else {
        return [RBQFetchedResultsControllerCacheObject objectInRealm:[self realmForCache]
                                                       forPrimaryKey:[self nameForFetchRequest:self.fetchRequest]];
    }
    
    return nil;
}

- (NSString *)cachePathWithName:(NSString *)name
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

- (NSString *)nameForFetchRequest:(RBQFetchRequest *)fetchRequest
{
    return [NSString stringWithFormat:@"%d-cache",fetchRequest.hash];
}

@end
