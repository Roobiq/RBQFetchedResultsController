//
//  RBQFetchedResultsController.m
//  RBQFetchedResultsControllerTest
//
//  Created by Lauren Smith on 1/2/15.
//  Copyright (c) 2015 Roobiq. All rights reserved.
//

#import "RBQFetchedResultsController.h"

#import "RLMObject+Utilities.h"
#import "RBQRealmNotificationManager.h"
#import "RBQControllerCacheObject.h"
#import "RBQSectionCacheObject.h"

@import UIKit;

#pragma mark - RBQFetchedResultsController

@interface RBQFetchedResultsController ()

@property (strong, nonatomic) RBQNotificationToken *notificationToken;
@property (strong, nonatomic) RLMNotificationToken *cacheNotificationToken;
@property (weak, nonatomic) RLMRealm *inMemoryRealmCache;

@end

#pragma mark - RBQFetchedResultsSectionInfo

@interface RBQFetchedResultsSectionInfo ()

// RBQFetchRequest to support retrieving section objects
@property (strong, nonatomic) RBQFetchRequest *fetchRequest;

// Section name key path to support retrieving section objects
@property (strong, nonatomic) NSString *sectionNameKeyPath;

// Create a RBQFetchedResultsSectionInfo
+ (instancetype)createSectionWithName:(NSString *)sectionName
                   sectionNameKeyPath:(NSString *)sectionNameKeyPath
                         fetchRequest:(RBQFetchRequest *)fetchRequest;

@end

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
    if (self.fetchRequest && self.sectionNameKeyPath) {
        
        RLMResults *fetchResults = [self.fetchRequest fetchObjects];
        
        return [fetchResults objectsWhere:@"%K == %@", self.sectionNameKeyPath, self.name];
    }
    else if (self.fetchRequest) {
        return [self.fetchRequest fetchObjects];
    }
    
    return nil;
}

- (NSUInteger)numberOfObjects
{
    return [self objects].count;
}

@end

#pragma mark - RBQStateObject

@interface RBQStateObject : NSObject

@property (strong, nonatomic) RLMRealm *realm;
@property (strong, nonatomic) RLMRealm *cacheRealm;
@property (strong, nonatomic) RLMResults *fetchResults;
@property (strong, nonatomic) RBQControllerCacheObject *cache;

@end

@implementation RBQStateObject

@end

#pragma mark - RBQChangeSetsObject

@interface RBQChangeSetsObject : NSObject

@property (strong, nonatomic) NSOrderedSet *cacheObjectsChangeSet;
@property (strong, nonatomic) NSOrderedSet *cacheSectionsChangeSet;
@property (strong, nonatomic) NSDictionary *cacheObjectToSafeObject;

@end

@implementation RBQChangeSetsObject

@end

#pragma mark - RBQSectionChangesObject

@interface RBQSectionChangesObject : NSObject

@property (strong, nonatomic) NSOrderedSet *oldCacheSections;
@property (strong, nonatomic) NSOrderedSet *sortedNewCacheSections;
@property (strong, nonatomic) NSOrderedSet *deletedCacheSections;
@property (strong, nonatomic) NSOrderedSet *insertedCacheSections;

@end

@implementation RBQSectionChangesObject

@end

#pragma mark - RBQSectionChangeObject

@interface RBQSectionChangeObject : NSObject

@property (strong, nonatomic) NSNumber *previousIndex;
@property (strong, nonatomic) NSNumber *updatedIndex;
@property (strong, nonatomic) RBQSectionCacheObject *section;
@property (assign, nonatomic) NSFetchedResultsChangeType changeType;

@end

@implementation RBQSectionChangeObject

@end

#pragma mark - RBQObjectChangeObject

@interface RBQObjectChangeObject : NSObject

@property (strong, nonatomic) NSIndexPath *previousIndexPath;
@property (strong, nonatomic) NSIndexPath *updatedIndexpath;
@property (assign, nonatomic) NSFetchedResultsChangeType changeType;
@property (strong, nonatomic) RBQSafeRealmObject *object;
@property (strong, nonatomic) RBQObjectCacheObject *previousCacheObject;
@property (strong, nonatomic) RBQObjectCacheObject *updatedCacheObject;

@end

@implementation RBQObjectChangeObject

@end

#pragma mark - RBQDerivedChangesObject

@interface RBQDerivedChangesObject : NSObject

@property (nonatomic, strong) NSOrderedSet *sectionChanges;
@property (nonatomic, strong) NSOrderedSet *deletedObjectChanges;
@property (nonatomic, strong) NSOrderedSet *insertedObjectChanges;
@property (nonatomic, strong) NSOrderedSet *movedObjectChanges;

@end

@implementation RBQDerivedChangesObject

@end

#pragma mark - RBQFetchedResultsController

@implementation RBQFetchedResultsController
@synthesize cacheName = _cacheName;

#pragma mark - Public Class

+ (void)deleteCacheWithName:(NSString *)name
{
    if (name) {
        NSError *error;
        if (![[NSFileManager defaultManager] removeItemAtPath:[RBQFetchedResultsController basePathForCacheWithName:name]
                                                        error:&error]) {
#ifdef DEBUG
            NSLog(@"%@",error.localizedDescription);
#endif
        }
    }
    // No name, so lets clear all caches
    else {
        NSError *error;
        if (![[NSFileManager defaultManager] removeItemAtPath:[RBQFetchedResultsController basePathForCaches]
                                                        error:&error]) {
#ifdef DEBUG
            NSLog(@"%@",error.localizedDescription);
#endif
        }
    }
}

#pragma mark - Private Class

// Create Realm instance for cache name
+ (RLMRealm *)realmForCacheName:(NSString *)cacheName
{
    return [RLMRealm realmWithPath:[RBQFetchedResultsController cachePathWithName:cacheName]];
}

//  Create a file path for Realm cache with a given name
+ (NSString *)cachePathWithName:(NSString *)name
{
    NSString *basePath = [RBQFetchedResultsController basePathForCaches];
    
    BOOL isDir = NO;
    NSError *error = nil;
    
    //Create a unique directory for each cache
    NSString *uniqueDirectory = [NSString stringWithFormat:@"/%@/",name];
    
    NSString *cachePath = [basePath stringByAppendingPathComponent:uniqueDirectory];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:cachePath isDirectory:&isDir] && isDir == NO) {
        [[NSFileManager defaultManager] createDirectoryAtPath:cachePath withIntermediateDirectories:NO attributes:nil error:&error];
    }
    
    NSString *fileName = [NSString stringWithFormat:@"%@.realm",name];
    
    cachePath = [cachePath stringByAppendingPathComponent:fileName];
    
    return cachePath;
}

+ (NSString *)basePathForCaches
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentPath = [paths objectAtIndex:0];
    BOOL isDir = NO;
    NSError *error = nil;
    
    //Base path for all caches
    NSString *basePath = [documentPath stringByAppendingPathComponent:@"/RBQFetchedResultsControllerCache"];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:basePath isDirectory:&isDir] && isDir == NO) {
        [[NSFileManager defaultManager] createDirectoryAtPath:basePath withIntermediateDirectories:NO attributes:nil error:&error];
    }
    
    return basePath;
}

+ (NSString *)basePathForCacheWithName:(NSString *)name
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentPath = [paths objectAtIndex:0];
    BOOL isDir = NO;
    NSError *error = nil;
    
    //Unique directory for the cache
    NSString *uniqueDirectory = [NSString stringWithFormat:@"/RBQFetchedResultsControllerCache/%@",name];
    
    NSString *cachePath = [documentPath stringByAppendingPathComponent:uniqueDirectory];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:cachePath isDirectory:&isDir] && isDir == NO) {
        [[NSFileManager defaultManager] createDirectoryAtPath:cachePath withIntermediateDirectories:NO attributes:nil error:&error];
    }
    
    return cachePath;
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
        
        [self registerChangeNotifications];
    }
    
    return self;
}

- (id)initWithFetchRequest:(RBQFetchRequest *)fetchRequest
        sectionNameKeyPath:(NSString *)sectionNameKeyPath
        inMemoryRealmCache:(RLMRealm *)inMemoryRealm
{
    self = [super init];
    
    if (self) {
        _inMemoryRealmCache = inMemoryRealm;
        _fetchRequest = fetchRequest;
        _sectionNameKeyPath = sectionNameKeyPath;
        
        [self registerChangeNotifications];
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

- (void)reset
{
    RLMRealm *cacheRealm = [self cacheRealm];
    
    [cacheRealm deleteAllObjects];
    
    [self performFetch];
}

- (RBQSafeRealmObject *)safeObjectAtIndexPath:(NSIndexPath *)indexPath
{
    RBQControllerCacheObject *cache = [self cache];
    
    RBQSectionCacheObject *section = cache.sections[indexPath.section];
    
    RBQObjectCacheObject *cacheObject = section.objects[indexPath.row];
    
    RLMObject *object = [RBQObjectCacheObject objectInRealm:self.fetchRequest.realm
                                             forCacheObject:cacheObject];
    
    return [RBQSafeRealmObject safeObjectFromObject:object];
}

- (id)objectAtIndexPath:(NSIndexPath *)indexPath
{
    RBQControllerCacheObject *cache = [self cache];
    
    RBQSectionCacheObject *section = cache.sections[indexPath.section];
    
    RBQObjectCacheObject *cacheObject = section.objects[indexPath.row];
    
    return [RBQObjectCacheObject objectInRealm:self.fetchRequest.realm
                                forCacheObject:cacheObject];
}

- (id)objectInRealm:(RLMRealm *)realm
        atIndexPath:(NSIndexPath *)indexPath
{
    RBQControllerCacheObject *cache = [self cache];
    
    RBQSectionCacheObject *section = cache.sections[indexPath.section];
    
    RBQObjectCacheObject *cacheObject = section.objects[indexPath.row];
    
    return [RBQObjectCacheObject objectInRealm:realm
                                forCacheObject:cacheObject];
}

- (NSIndexPath *)indexPathForSafeObject:(RBQSafeRealmObject *)safeObject
{
    RLMRealm *realm = [self cacheRealm];
    
    RBQControllerCacheObject *cache = [self cache];
    
    RBQObjectCacheObject *cacheObject =
    [RBQObjectCacheObject objectInRealm:realm forPrimaryKey:safeObject.primaryKeyValue];
    
    NSInteger sectionIndex = [cache.sections indexOfObject:cacheObject.section];
    NSInteger rowIndex = [cacheObject.section.objects indexOfObject:cacheObject];
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:rowIndex inSection:sectionIndex];
    
    return indexPath;
}

- (NSIndexPath *)indexPathForObject:(RLMObject *)object
{
    RBQControllerCacheObject *cache = [self cache];
    
    RBQObjectCacheObject *cacheObject =
    [RBQObjectCacheObject cacheObjectInRealm:[self cacheRealm]
                                   forObject:object];
    
    NSInteger sectionIndex = [cache.sections indexOfObject:cacheObject.section];
    NSInteger rowIndex = [cacheObject.section.objects indexOfObject:cacheObject];
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:rowIndex inSection:sectionIndex];
    
    return indexPath;
}

- (NSInteger)numberOfRowsForSectionIndex:(NSInteger)index
{
    RBQControllerCacheObject *cache = [self cache];
    
    RBQSectionCacheObject *section = cache.sections[index];
    
    return section.objects.count;
}

- (NSInteger)numberOfSections
{
    RBQControllerCacheObject *cache = [self cache];
    
    return cache.sections.count;
}

- (NSString *)titleForHeaderInSection:(NSInteger)section
{
    RBQControllerCacheObject *cache = [self cache];
    
    RBQSectionCacheObject *sectionInfo = cache.sections[section];
    
    return sectionInfo.name;
}

#pragma mark - Getters

- (RLMResults *)fetchedObjects
{
    if (self.fetchRequest) {
        return [self.fetchRequest fetchObjects];
    }
    
    return nil;
}

#pragma mark - Private

// Register the change notification from RBQRealmNotificationManager
- (void)registerChangeNotifications
{
    self.notificationToken =
    [[RBQRealmNotificationManager defaultManager] addNotificationBlock:
     ^(NSDictionary *entityChanges,
       RLMRealm *realm)
     {
         // Grab the entity changes object if it is available
         RBQEntityChangesObject *entityChangesObject = [entityChanges objectForKey:self.fetchRequest.entityName];
         
         if (entityChangesObject) {
             
#ifdef DEBUG
             NSLog(@"%lu Added Objects",(unsigned long)entityChangesObject.addedSafeObjects.count);
             NSLog(@"%lu Deleted Objects",(unsigned long)entityChangesObject.deletedSafeObjects.count);
             NSLog(@"%lu Changed Objects",(unsigned long)entityChangesObject.changedSafeObjects.count);
#endif
             
             [self calculateChangesWithAddedSafeObjects:entityChangesObject.addedSafeObjects
                                     deletedSafeObjects:entityChangesObject.deletedSafeObjects
                                     changedSafeObjects:entityChangesObject.changedSafeObjects
                                                  realm:realm];
         }
     }];
    
    // Notification block to update the state of the cache when the cache Realm updates
    self.cacheNotificationToken =
    [[self cacheRealm] addNotificationBlock:^(NSString *notification, RLMRealm *realm) {
        RBQControllerCacheObject *cache = [self cacheInRealm:realm];
        
        if (cache.state == RBQControllerCacheStateProcessing) {
            [realm beginWriteTransaction];
            cache.state = RBQControllerCacheStateReady;
            [realm commitWriteTransaction];
        }
    }];
}

#pragma mark - Change Calculations

- (void)calculateChangesWithAddedSafeObjects:(NSSet *)addedSafeObjects
                          deletedSafeObjects:(NSSet *)deletedSafeObjects
                          changedSafeObjects:(NSSet *)changedSafeObjects
                                       realm:(RLMRealm *)realm
{
#ifdef DEBUG
    NSAssert(addedSafeObjects, @"Added safe objects can't be nil");
    NSAssert(deletedSafeObjects, @"Deleted safe objects can't be nil");
    NSAssert(changedSafeObjects, @"Changed safe objects can't be nil");
    NSAssert(realm, @"Realm can't be nil");
#endif
    
    if ([self.delegate respondsToSelector:@selector(controllerWillChangeContent:)])
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate controllerWillChangeContent:self];
        });
    }
    
    RBQStateObject *state = [self createStateObjectWithFetchRequest:self.fetchRequest
                                                              realm:realm
                                                              cache:[self cache]
                                                         cacheRealm:[self cacheRealm]];
    
    RBQChangeSetsObject *changeSets = [self createChangeSetsWithAddedSafeObjects:addedSafeObjects
                                                              deletedSafeObjects:deletedSafeObjects
                                                              changedSafeObjects:changedSafeObjects
                                                                           state:state];
#ifdef DEBUG
    NSLog(@"%lu Object Changes",(unsigned long)changeSets.cacheObjectsChangeSet.count);
    NSLog(@"%lu Section Changes",(unsigned long)changeSets.cacheSectionsChangeSet.count);
#endif
    
    // Make sure we actually identified changes
    // (changes might not match entity name)
    if (!changeSets) {
#ifdef DEBUG
        NSLog(@"No change objects or section changes found!");
#endif
        return;
    }
    
    RBQSectionChangesObject *sectionChanges = [self createSectionChangesWithChangeSets:changeSets
                                                                                 state:state];
    
    [state.cacheRealm beginWriteTransaction];
    
    // Update the state to make sure we rebuild cache if save fails
    state.cache.state = RBQControllerCacheStateProcessing;
    
    // Create Object To Gather Up Derived Changes
    RBQDerivedChangesObject *derivedChanges = [self deriveChangesWithChangeSets:changeSets
                                                                 sectionChanges:sectionChanges
                                                                          state:state];
#ifdef DEBUG
    NSLog(@"%lu Derived Added Objects",(unsigned long)derivedChanges.insertedObjectChanges.count);
    NSLog(@"%lu Derived Deleted Objects",(unsigned long)derivedChanges.deletedObjectChanges.count);
    NSLog(@"%lu Derived Moved Objects",(unsigned long)derivedChanges.movedObjectChanges.count);
#endif
    
    // Apply Derived Changes To Cache
    [self applyDerivedChangesToCache:derivedChanges
                               state:state];
    
    [state.cacheRealm commitWriteTransaction];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(controllerDidChangeContent:)]) {
            [self.delegate controllerDidChangeContent:self];
        }
    });
}

- (void)applyDerivedChangesToCache:(RBQDerivedChangesObject *)derivedChanges
                             state:(RBQStateObject *)state
{
#ifdef DEBUG
    NSAssert(derivedChanges, @"Derived changes can't be nil!");
    NSAssert(state, @"State can't be nil!");
#endif
    
    // Apply Section Changes To Cache
    for (RBQSectionChangeObject *sectionChange in derivedChanges.sectionChanges) {
        
        if (sectionChange.changeType == NSFetchedResultsChangeDelete) {
            // Remove the section from Realm cache
            [state.cache.sections removeObjectAtIndex:sectionChange.previousIndex.unsignedIntegerValue];
        }
        else if (sectionChange.changeType == NSFetchedResultsChangeInsert) {
            // Add the section to the cache
            [state.cache.sections insertObject:sectionChange.section
                                       atIndex:sectionChange.updatedIndex.unsignedIntegerValue];
        }
    }
    
    // Apply Object Changes To Cache (Must apply in correct order!)
    for (NSOrderedSet *objectChanges in @[derivedChanges.deletedObjectChanges,
                                     derivedChanges.insertedObjectChanges,
                                     derivedChanges.movedObjectChanges]) {
        
        for (RBQObjectChangeObject *objectChange in objectChanges) {
            
            if (objectChange.changeType == NSFetchedResultsChangeDelete) {
                // Remove the object
                [state.cacheRealm deleteObject:objectChange.previousCacheObject];
            }
            else if (objectChange.changeType == NSFetchedResultsChangeInsert) {
                // Insert the object
                [state.cacheRealm addObject:objectChange.updatedCacheObject];
                
                // Get the section and add it to it
                RBQSectionCacheObject *section =
                [RBQSectionCacheObject objectInRealm:state.cacheRealm
                                       forPrimaryKey:objectChange.updatedCacheObject.sectionKeyPathValue];
                
#ifdef DEBUG
                NSAssert(section.objects.count >= objectChange.updatedIndexpath.row, @"Attempting to insert object at index greater than count!");
#endif
                [section.objects insertObject:objectChange.updatedCacheObject
                                      atIndex:objectChange.updatedIndexpath.row];
                
                objectChange.updatedCacheObject.section = section;
            }
            else if (objectChange.changeType == NSFetchedResultsChangeMove) {
                // Delete to remove it from previous section
                [state.cacheRealm deleteObject:objectChange.previousCacheObject];
                
                // Add it back in
                [state.cacheRealm addObject:objectChange.updatedCacheObject];
                
                // Get the section and add it to it
                RBQSectionCacheObject *section =
                [RBQSectionCacheObject objectInRealm:state.cacheRealm
                                       forPrimaryKey:objectChange.updatedCacheObject.sectionKeyPathValue];
                
                [section.objects insertObject:objectChange.updatedCacheObject
                                      atIndex:objectChange.updatedIndexpath.row];
                
                objectChange.updatedCacheObject.section = section;
            }
        }
    }
}

#pragma mark - Internal Cache

// Create the internal cache for a fetch request
- (void)createCacheWithRealm:(RLMRealm *)cacheRealm
                   cacheName:(NSString *)cacheName
             forFetchRequest:(RBQFetchRequest *)fetchRequest
          sectionNameKeyPath:(NSString *)sectionNameKeyPath
{
    RLMResults *fetchResults = [fetchRequest fetchObjects];
    
    // Check if we have a cache already
    RBQControllerCacheObject *controllerCache = [RBQControllerCacheObject objectInRealm:cacheRealm
                                                                          forPrimaryKey:cacheName];
    
    [cacheRealm beginWriteTransaction];
    
    /**
     *  Reset the cache if the fetchRequest hash doesn't match
     *  The count in the cache is off from the fetch results
     *  The state was left in processing
     *  The section name key path has changed
     */
    if (controllerCache.fetchRequestHash != fetchRequest.hash ||
        controllerCache.objects.count != fetchResults.count ||
        controllerCache.state == RBQControllerCacheStateProcessing ||
        ![controllerCache.sectionNameKeyPath isEqualToString:sectionNameKeyPath]) {
        
        [cacheRealm deleteAllObjects];
        
        controllerCache = nil;
    }
    
    if (!controllerCache) {
        
        controllerCache = [RBQControllerCacheObject cacheWithName:cacheName
                                                 fetchRequestHash:fetchRequest.hash];
        
        RBQSectionCacheObject *section = nil;
        
        // Iterate over the results to create the section information
        NSString *currentSectionTitle = nil;
        
        //No sections being used, so create default section
        if (!sectionNameKeyPath) {
            
            currentSectionTitle = @"";
            
            section = [RBQSectionCacheObject cacheWithName:currentSectionTitle];
        }
        
        NSUInteger count = 0;
        
        for (RLMObject *object in fetchResults) {
            // Keep track of the count
            count ++;
            
            if (sectionNameKeyPath) {
                
                // Check your sectionNameKeyPath if a crash occurs...
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
            
            // Save the final section (or if not using sections, the only section)
            if (count == fetchResults.count) {
                
                // Add the section to Realm
                [cacheRealm addObject:section];
                
                [controllerCache.sections addObject:section];
            }
            
            // Create the cache object
            RBQObjectCacheObject *cacheObject = [RBQObjectCacheObject createCacheObjectWithObject:object
                                                                              sectionKeyPathValue:currentSectionTitle];
            
            cacheObject.section = section;
            
            if (section) {
                [section.objects addObject:cacheObject];
            }
            
            [controllerCache.objects addObject:cacheObject];
        }
        
        // Set the section name key path, if available
        if (sectionNameKeyPath) {
            controllerCache.sectionNameKeyPath = sectionNameKeyPath;
        }
        
        // Add cache to Realm
        [cacheRealm addObject:controllerCache];
    }
    
    [cacheRealm commitWriteTransaction];
}

#pragma mark - RBQStateObject

- (RBQStateObject *)createStateObjectWithFetchRequest:(RBQFetchRequest *)fetchRequest
                                                realm:(RLMRealm *)realm
                                                cache:(RBQControllerCacheObject *)cache
                                           cacheRealm:(RLMRealm *)cacheRealm
{
    
#ifdef DEBUG
    NSAssert(fetchRequest, @"Fetch request can't be nil");
    NSAssert(realm, @"Realm can't be nil");
    NSAssert(cache, @"Cache can't be nil");
    NSAssert(cacheRealm, @"Cache Realm can't be nil");
#endif
    
    // Setup the state object
    RBQStateObject *stateObject = [[RBQStateObject alloc] init];
    
    stateObject.realm = realm;
    
    // Get the new list of safe fetch objects
    stateObject.fetchResults = [fetchRequest fetchObjectsInRealm:realm];
    
    stateObject.cache = cache;
    
    stateObject.cacheRealm = cacheRealm;
    
    return stateObject;
}

#pragma mark - RBQChangeSetsObject

- (RBQChangeSetsObject *)createChangeSetsWithAddedSafeObjects:(NSSet *)addedSafeObjects
                                           deletedSafeObjects:(NSSet *)deletedSafeObjects
                                           changedSafeObjects:(NSSet *)changedSafeObjects
                                                        state:(RBQStateObject *)state
{
    
#ifdef DEBUG
    NSAssert(addedSafeObjects, @"Added safe objects request can't be nil");
    NSAssert(deletedSafeObjects, @"Deleted safe objects can't be nil");
    NSAssert(changedSafeObjects, @"Changed safe objects can't be nil");
    NSAssert(state, @"State object can't be nil");
#endif
    
    // Get Sections In Change Set
    NSMutableOrderedSet *cacheSectionsInChangeSet = [[NSMutableOrderedSet alloc] init];
    NSMutableOrderedSet *cacheObjectsChangeSet = [[NSMutableOrderedSet alloc] init];
    NSMutableDictionary *cacheObjectToSafeObject = @{}.mutableCopy;
    
    for (NSSet *changedObjects in @[addedSafeObjects, deletedSafeObjects, changedSafeObjects]) {
        
        for (RBQSafeRealmObject *safeObject in changedObjects) {
            
            // Get the section titles in change set
            // Attempt to get the object from non-cache Realm
            RLMObject *object = [RBQSafeRealmObject objectInRealm:state.realm
                                                   fromSafeObject:safeObject];
            
            // If the changed object doesn't match the predicate and
            // was not already in the cache, then skip it
            if ([self.fetchRequest evaluateObject:object] &&
                [RBQObjectCacheObject objectInRealm:state.cacheRealm
                                      forPrimaryKey:safeObject.primaryKeyValue]) {
                continue;
            }
            
            NSString *sectionTitle = nil;
            
            if (object &&
                self.sectionNameKeyPath) {
                sectionTitle = [object valueForKey:self.sectionNameKeyPath];
            }
            else if (self.sectionNameKeyPath) {
                RBQObjectCacheObject *oldCacheObject =
                [RBQObjectCacheObject objectInRealm:state.cacheRealm
                                      forPrimaryKey:safeObject.primaryKeyValue];
                
                sectionTitle = oldCacheObject.section.name;
            }
            // We aren't using sections so create a dummy one with no text
            else {
                sectionTitle = @"";
            }
            
            if (sectionTitle) {
                RBQSectionCacheObject *section = [RBQSectionCacheObject objectInRealm:state.cacheRealm
                                                                        forPrimaryKey:sectionTitle];
                
                if (!section) {
                    section = [RBQSectionCacheObject cacheWithName:sectionTitle];
                }
                
                [cacheSectionsInChangeSet addObject:section];
            }
            
            // Get the cache object
            RBQObjectCacheObject *cacheObject =
            [RBQObjectCacheObject createCacheObjectWithSafeObject:safeObject
                                              sectionKeyPathValue:sectionTitle];
            
            [cacheObjectsChangeSet addObject:cacheObject];
            
            // Set the map to quickly retrieve safe objects later on
            [cacheObjectToSafeObject setObject:safeObject forKey:cacheObject];
        }
    }
    
    if (cacheSectionsInChangeSet.count > 0 ||
        cacheObjectsChangeSet.count > 0) {
        
        RBQChangeSetsObject *changeSets = [[RBQChangeSetsObject alloc] init];
        
        changeSets.cacheSectionsChangeSet = cacheSectionsInChangeSet.copy;
        changeSets.cacheObjectsChangeSet = cacheObjectsChangeSet.copy;
        changeSets.cacheObjectToSafeObject = cacheObjectToSafeObject.copy;
        
        return changeSets;
    }
    
    return nil;
}

#pragma mark - RBQSectionChangesObject

- (RBQSectionChangesObject *)createSectionChangesWithChangeSets:(RBQChangeSetsObject *)changeSets
                                                          state:(RBQStateObject *)state
{
#ifdef DEBUG
    NSAssert(changeSets, @"Change sets can't be nil");
    NSAssert(state, @"State can't be nil");
#endif
    
    // Get Old Sections
    NSMutableOrderedSet *oldSections = [[NSMutableOrderedSet alloc] init];
    
    for (RBQSectionCacheObject *section in state.cache.sections) {
        [oldSections addObject:section];
    }
    
    // Combine Old With Change Set (without dupes!)
    NSMutableOrderedSet *oldAndChange = [NSMutableOrderedSet orderedSetWithOrderedSet:oldSections];
    
    for (RBQSectionCacheObject *section in changeSets.cacheSectionsChangeSet) {
        if (![oldAndChange containsObject:section]) {
            [oldAndChange addObject:section];
        }
    }
    
    NSMutableOrderedSet *newSections = [[NSMutableOrderedSet alloc] init];
    NSMutableOrderedSet *deletedSections = [[NSMutableOrderedSet alloc] init];
    
    // Loop through to identify the new sections in fetchResults
    for (RBQSectionCacheObject *section in oldAndChange) {
        
        RLMResults * sectionResults = nil;
        
        if (self.sectionNameKeyPath) {
            sectionResults = [state.fetchResults objectsWhere:@"%K == %@",
                              self.sectionNameKeyPath,
                              section.name];
        }
        // We aren't using sections, so just use all results
        else {
            sectionResults = state.fetchResults;
        }
        
        if (sectionResults.count > 0) {
            RLMObject *firstObject = [sectionResults firstObject];
            RLMObject *lastObject = [sectionResults lastObject];
            NSInteger firstObjectIndex = [state.fetchResults indexOfObject:firstObject];
            NSInteger lastObjectIndex = [state.fetchResults indexOfObject:lastObject];
            
            // Write change to object index to cache Realm
            [state.cacheRealm beginWriteTransaction];
            
            section.firstObjectIndex = firstObjectIndex;
            section.lastObjectIndex = lastObjectIndex;
            
            [state.cacheRealm commitWriteTransaction];
            
            // Get the entire list of all sections after the change
            [newSections addObject:section];
        }
        // Add to deleted only if this section was already in cache
        // Possible to add a section that has no data (so we don't want to insert or delete it)
        else if ([state.cache.sections indexOfObject:section] != NSNotFound) {
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
    NSMutableOrderedSet *insertedSections = [NSMutableOrderedSet orderedSetWithOrderedSet:newSections];
    // Remove the old sections to identify only the inserted
    [insertedSections removeObjectsInArray:oldSections.array];
    
    RBQSectionChangesObject *sectionChanges = [[RBQSectionChangesObject alloc] init];
    
    // Save the section collections
    sectionChanges.oldCacheSections = oldSections.copy;
    sectionChanges.deletedCacheSections = deletedSections.copy;
    sectionChanges.insertedCacheSections = insertedSections.copy;
    sectionChanges.sortedNewCacheSections = newSections.copy;
    
    return sectionChanges;
}

#pragma mark - RBQObjectChangeObject

- (RBQObjectChangeObject *)objectChangeWithCacheObject:(RBQObjectCacheObject *)cacheObject
                                            changeSets:(RBQChangeSetsObject *)changeSets
                                        sectionChanges:(RBQSectionChangesObject *)sectionChanges
                                                 state:(RBQStateObject *)state
{
#ifdef DEBUG
    NSAssert(cacheObject, @"Cache object can't be nil");
    NSAssert(changeSets, @"Change sets can't be nil");
    NSAssert(sectionChanges, @"Change sets can't be nil");
    NSAssert(state, @"State can't be nil");
#endif
    
    RBQObjectChangeObject *objectChange = [[RBQObjectChangeObject alloc] init];
    
    objectChange.previousCacheObject =
    [RBQObjectCacheObject objectInRealm:state.cacheRealm
                          forPrimaryKey:cacheObject.primaryKeyStringValue];
    
    RBQSectionCacheObject *oldSectionForObject = objectChange.previousCacheObject.section;
    
    // Get old indexPath if we can
    if (oldSectionForObject &&
        objectChange.previousCacheObject) {
        
        NSInteger oldSectionIndex = [sectionChanges.oldCacheSections indexOfObject:oldSectionForObject];
        
        NSInteger oldRowIndex = [oldSectionForObject.objects indexOfObject:objectChange.previousCacheObject];
        
        objectChange.previousIndexPath = [NSIndexPath indexPathForRow:oldRowIndex inSection:oldSectionIndex];
    }
    
    // Get new indexPath if we can
    RLMObject *updatedObject = [RBQObjectCacheObject objectInRealm:state.realm
                                                    forCacheObject:cacheObject];
    
    if (updatedObject) {
        NSInteger newAllObjectIndex = [state.fetchResults indexOfObject:updatedObject];
        
        if (newAllObjectIndex != NSNotFound) {
            RBQSectionCacheObject *newSection = nil;
            
            NSInteger newSectionIndex = 0;
            
            for (RBQSectionCacheObject *section in sectionChanges.sortedNewCacheSections) {
                if (newAllObjectIndex >= section.firstObjectIndex &&
                    newAllObjectIndex <= section.lastObjectIndex) {
                    
                    newSection = section;
                    
                    break;
                }
                
                newSectionIndex ++;
            }
            
            NSInteger newRowIndex = newAllObjectIndex - newSection.firstObjectIndex;
            
            objectChange.updatedCacheObject = cacheObject;
            objectChange.updatedIndexpath = [NSIndexPath indexPathForRow:newRowIndex
                                                            inSection:newSectionIndex];
        }
    }
    
    if (objectChange.previousIndexPath ||
        objectChange.updatedIndexpath) {
        
        return objectChange;
    }
    
    return nil;
}

#pragma mark - RBQDerivedChangesObject

- (RBQDerivedChangesObject *)deriveChangesWithChangeSets:(RBQChangeSetsObject *)changeSets
                                          sectionChanges:(RBQSectionChangesObject *)sectionChanges
                                                   state:(RBQStateObject *)state
{
#ifdef DEBUG
    NSAssert(changeSets, @"Change sets can't be nil!");
    NSAssert(sectionChanges, @"Section changes can't be nil!");
    NSAssert(state, @"State can't be nil!");
#endif
    
    RBQDerivedChangesObject *derivedChanges = [[RBQDerivedChangesObject alloc] init];
    
    // ---------------
    // Section Changes
    // ---------------
    
    [self updateDerivedChangesWithSectionChanges:derivedChanges
                                      changeSets:changeSets
                                  sectionChanges:sectionChanges];
#ifdef DEBUG
    NSAssert(derivedChanges.sectionChanges, @"Sections changes array can't be nil!");
#endif
    
    // ---------------
    // Object Changes
    // ---------------
    
    [self updateDerivedChangesWithObjectChanges:derivedChanges
                                     changeSets:changeSets
                                 sectionChanges:sectionChanges
                                          state:state];
    
#ifdef DEBUG
    NSAssert(derivedChanges.deletedObjectChanges, @"Deleted objects array can't be nil!");
    NSAssert(derivedChanges.insertedObjectChanges, @"Inserted objects array can't be nil!");
    NSAssert(derivedChanges.movedObjectChanges, @"Moved objects array can't be nil!");
#endif
    
    return derivedChanges;
}

- (void)updateDerivedChangesWithSectionChanges:(RBQDerivedChangesObject *)derivedChanges
                                    changeSets:(RBQChangeSetsObject *)changeSets
                                sectionChanges:(RBQSectionChangesObject *)sectionChanges
{
#ifdef DEBUG
    NSAssert(changeSets, @"Change sets can't be nil!");
    NSAssert(sectionChanges, @"Section changes can't be nil!");
    NSAssert(self.fetchRequest, @"Fetch request can't be nil!");
#endif
    
    NSMutableOrderedSet *derivedSectionChanges = [[NSMutableOrderedSet alloc] init];
    
    // Deleted Sections
    for (RBQSectionCacheObject *section in sectionChanges.deletedCacheSections) {
        
        NSInteger oldSectionIndex = [sectionChanges.oldCacheSections indexOfObject:section];
        
        RBQFetchedResultsSectionInfo *sectionInfo =
        [RBQFetchedResultsSectionInfo createSectionWithName:section.name
                                         sectionNameKeyPath:self.sectionNameKeyPath
                                               fetchRequest:self.fetchRequest];
        
        if ([self.delegate
             respondsToSelector:@selector(controller:didChangeSection:atIndex:forChangeType:)])
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.delegate controller:self
                         didChangeSection:sectionInfo
                                  atIndex:oldSectionIndex
                            forChangeType:NSFetchedResultsChangeDelete];
            });
        }
        
        // Create the section change object
        RBQSectionChangeObject *sectionChange = [[RBQSectionChangeObject alloc] init];
        sectionChange.previousIndex = @(oldSectionIndex);
        sectionChange.section = section;
        sectionChange.changeType = NSFetchedResultsChangeDelete;
        
        [derivedSectionChanges addObject:sectionChange];
    }
    // Inserted Sections
    for (RBQSectionCacheObject *section in sectionChanges.insertedCacheSections) {
        
        NSInteger newSectionIndex = [sectionChanges.sortedNewCacheSections indexOfObject:section];
        
        RBQFetchedResultsSectionInfo *sectionInfo =
        [RBQFetchedResultsSectionInfo createSectionWithName:section.name
                                         sectionNameKeyPath:self.sectionNameKeyPath
                                               fetchRequest:self.fetchRequest];
        
        if ([self.delegate
             respondsToSelector:@selector(controller:didChangeSection:atIndex:forChangeType:)])
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.delegate controller:self
                         didChangeSection:sectionInfo
                                  atIndex:newSectionIndex
                            forChangeType:NSFetchedResultsChangeInsert];
            });
        }
        
        // Create the section change object
        RBQSectionChangeObject *sectionChange = [[RBQSectionChangeObject alloc] init];
        sectionChange.updatedIndex = @(newSectionIndex);
        sectionChange.section = section;
        sectionChange.changeType = NSFetchedResultsChangeInsert;
        
        [derivedSectionChanges addObject:sectionChange];
    }
    
    derivedChanges.sectionChanges = derivedSectionChanges.copy;
}

- (void)updateDerivedChangesWithObjectChanges:(RBQDerivedChangesObject *)derivedChanges
                                   changeSets:(RBQChangeSetsObject *)changeSets
                               sectionChanges:(RBQSectionChangesObject *)sectionChanges
                                        state:(RBQStateObject *)state
{
#ifdef DEBUG
    NSAssert(derivedChanges, @"Derived changes can't be nil!");
    NSAssert(changeSets, @"Change sets can't be nil!");
    NSAssert(sectionChanges, @"Section changes can't be nil!");
    NSAssert(state, @"State can't be nil!");
#endif
    
    NSMutableOrderedSet *deletedObjectChanges = [[NSMutableOrderedSet alloc] init];
    NSMutableOrderedSet *insertedObjectChanges = [[NSMutableOrderedSet alloc] init];
    NSMutableOrderedSet *movedObjectChanges = [[NSMutableOrderedSet alloc] init];
    
    NSUInteger countChange = ABS(state.fetchResults.count - state.cache.objects.count);
    
    for (RBQObjectCacheObject *cacheObject in changeSets.cacheObjectsChangeSet) {
        
        RBQObjectChangeObject *objectChange = [self objectChangeWithCacheObject:cacheObject
                                                                     changeSets:changeSets
                                                                 sectionChanges:sectionChanges
                                                                          state:state];
        
        // If we didn't get an object change then skip
        if (!objectChange) {
            continue;
        }
        
        // Deleted Objects
        if (!objectChange.updatedIndexpath &&
            objectChange.previousIndexPath) {
            
            RBQSafeRealmObject *safeObject =
            [changeSets.cacheObjectToSafeObject objectForKey:objectChange.previousCacheObject];
            
#ifdef DEBUG
            NSAssert(safeObject, @"Safe object can't be nil!");
#endif
            
            if ([self.delegate respondsToSelector:
                 @selector(controller:didChangeObject:atIndexPath:forChangeType:newIndexPath:)])
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.delegate controller:self
                              didChangeObject:safeObject
                                  atIndexPath:objectChange.previousIndexPath
                                forChangeType:NSFetchedResultsChangeDelete
                                 newIndexPath:nil];
                });
            }
            
            objectChange.changeType = NSFetchedResultsChangeDelete;
            
            [deletedObjectChanges addObject:objectChange];
        }
        // Inserted Objects
        else if (objectChange.updatedIndexpath &&
                 !objectChange.previousIndexPath) {
            
            RBQSafeRealmObject *safeObject =
            [changeSets.cacheObjectToSafeObject objectForKey:objectChange.updatedCacheObject];
            
#ifdef DEBUG
            NSAssert(safeObject, @"Safe object can't be nil!");
#endif
            
            if ([self.delegate respondsToSelector:
                 @selector(controller:didChangeObject:atIndexPath:forChangeType:newIndexPath:)])
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.delegate controller:self
                              didChangeObject:safeObject
                                  atIndexPath:nil
                                forChangeType:NSFetchedResultsChangeInsert
                                 newIndexPath:objectChange.updatedIndexpath];
                });
            }
            objectChange.changeType = NSFetchedResultsChangeInsert;
            
            // Insert and sort items (fixes crashes when there are no objects yet!)
            NSRange sortRange = NSMakeRange(0, insertedObjectChanges.count);
            NSUInteger indexToInsert =
            [insertedObjectChanges indexOfObject:objectChange
                                   inSortedRange:sortRange
                                         options:NSBinarySearchingInsertionIndex
                                 usingComparator:^NSComparisonResult(RBQObjectChangeObject *obj1,
                                                                     RBQObjectChangeObject *obj2) {
                                     // Compare the indexPaths
                                     return [obj1.updatedIndexpath compare:obj2.updatedIndexpath];
                                     }];
            
            [insertedObjectChanges insertObject:objectChange atIndex:indexToInsert];
        }
        // Moved Objects
        // Compare the row changes to the count change
        // Fixes issue where we miss a move because indexes are now the same because of deletes/inserts
        else if ((objectChange.previousIndexPath.section == objectChange.updatedIndexpath.section) &&
                 (ABS(objectChange.previousIndexPath.row - objectChange.updatedIndexpath.row) != countChange)) {
            
            RBQSafeRealmObject *safeObject =
            [changeSets.cacheObjectToSafeObject objectForKey:objectChange.previousCacheObject];
            
#ifdef DEBUG
            NSAssert(safeObject, @"Safe object can't be nil!");
#endif
            
            if ([self.delegate respondsToSelector:
                 @selector(controller:didChangeObject:atIndexPath:forChangeType:newIndexPath:)])
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.delegate controller:self
                              didChangeObject:safeObject
                                  atIndexPath:objectChange.previousIndexPath
                                forChangeType:NSFetchedResultsChangeMove
                                 newIndexPath:objectChange.updatedIndexpath];
                });
            }
            
            objectChange.changeType = NSFetchedResultsChangeMove;
            
            [movedObjectChanges addObject:objectChange];
        }
        // Updated Objects
        else {
            
            RBQSafeRealmObject *safeObject =
            [changeSets.cacheObjectToSafeObject objectForKey:objectChange.previousCacheObject];
            
#ifdef DEBUG
            NSAssert(safeObject, @"Safe object can't be nil!");
#endif
            
            if ([self.delegate respondsToSelector:
                 @selector(controller:didChangeObject:atIndexPath:forChangeType:newIndexPath:)])
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.delegate controller:self
                              didChangeObject:safeObject
                                  atIndexPath:objectChange.updatedIndexpath
                                forChangeType:NSFetchedResultsChangeUpdate
                                 newIndexPath:nil];
                });
            }
        }
    }
    
    derivedChanges.deletedObjectChanges = deletedObjectChanges.copy;
    derivedChanges.insertedObjectChanges = insertedObjectChanges.copy;
    derivedChanges.movedObjectChanges = movedObjectChanges.copy;
}

#pragma mark - Helpers

// Create instance of Realm for internal cache
- (RLMRealm *)cacheRealm
{
    if (self.cacheName) {
        // Insert migration if needed! --> [self performMigrationForRealmAtPath:]
        return [RBQFetchedResultsController realmForCacheName:self.cacheName];
    }
    else if (self.inMemoryRealmCache) {
        return self.inMemoryRealmCache;
    }
    else {
        // Insert migration if needed! --> [self performMigrationForRealmAtPath:]
        self.inMemoryRealmCache = [RLMRealm inMemoryRealmWithIdentifier:[self nameForFetchRequest:self.fetchRequest]];
        
        return self.inMemoryRealmCache;
    }
    
    return nil;
}

/**
 *  If you need to perform a migration, use this method and call the Realm that contains the cache
 *
 *  For example:
 *
 *  NSString *path = [RBQFetchedResultsController cachePathWithName:[self nameForFetchRequest:self.fetchRequest]];
 *
 *  or
 *
 *  NSString *path = [RBQFetchedResultsController cachePathWithName:self.cacheName];
 *
 *  IMPORTANT: YOU MUST ALSO RUN A MIGRATION ON ANY OTHER REALMS!
 *
 *  @param path path for the Realm that contains the controller cache
 */
- (void)performMigrationForRealmAtPath:(NSString *)path
{
    [RLMRealm setSchemaVersion:1 forRealmAtPath:path
            withMigrationBlock:^(RLMMigration *migration, NSUInteger oldSchemaVersion) {
        
        if (oldSchemaVersion < 1) {
            [migration enumerateObjects:[RBQControllerCacheObject className]
                                  block:^(RLMObject *oldObject, RLMObject *newObject) {
                                    
                                      // Insert an invalid section name key path to make sure cache is rebuilt
                                      newObject[@"sectionNameKeyPath"] = @"invalidSectionNameKeyPath";
                                  }];
        }
    }];
}

// Retrieve internal cache
- (RBQControllerCacheObject *)cache
{
    RBQControllerCacheObject *cache = [self cacheInRealm:[self cacheRealm]];
    
    if (!cache) {
        [self performFetch];
        
        cache = [self cacheInRealm:[self cacheRealm]];
    }
    
    return cache;
}

- (RBQControllerCacheObject *)cacheInRealm:(RLMRealm *)realm
{
    if (self.cacheName) {
        
        return [RBQControllerCacheObject objectInRealm:realm
                                         forPrimaryKey:self.cacheName];
    }
    else {
        return [RBQControllerCacheObject objectInRealm:realm
                                         forPrimaryKey:[self nameForFetchRequest:self.fetchRequest]];
    }
    
    return nil;
}

// Create a computed name for a fetch request
- (NSString *)nameForFetchRequest:(RBQFetchRequest *)fetchRequest
{
    return [NSString stringWithFormat:@"%lu-cache",(unsigned long)fetchRequest.hash];
}

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

@end
