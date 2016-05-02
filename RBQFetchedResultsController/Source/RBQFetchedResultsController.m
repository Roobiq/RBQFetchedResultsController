//
//  RBQFetchedResultsController.m
//  RBQFetchedResultsControllerTest
//
//  Created by Adam Fish on 1/2/15.
//  Copyright (c) 2015 Roobiq. All rights reserved.
//

#import "RBQFetchedResultsController.h"

#import "RLMObject+Utilities.h"
#import "RBQControllerCacheObject.h"
#import "RBQSectionCacheObject.h"
#import "RLMObject+Utilities.h"

#import <objc/runtime.h>

@import UIKit;

#pragma mark - Constants
static void * RBQArrayFetchRequestContext = &RBQArrayFetchRequestContext;

#pragma mark - RBQFetchedResultsController

@interface RBQFetchedResultsController ()

@property (nonatomic, strong) RLMNotificationToken *notificationToken;
@property (nonatomic, strong) id<RLMCollection> notificationCollection;
@property (nonatomic, strong) NSRunLoop *notificationRunLoop;

@property (strong, nonatomic) RLMRealm *inMemoryRealm;
@property (strong, nonatomic) RLMRealm *realmForMainThread; // Improves scroll performance

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

- (id<RLMCollection>)objects
{
    if (self.fetchRequest && self.sectionNameKeyPath) {
        
        id<RLMCollection> fetchResults = [self.fetchRequest fetchObjects];
        
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
@property (strong, nonatomic) id<RLMCollection> fetchResults;
@property (strong, nonatomic) RBQControllerCacheObject *cache;

@end

@implementation RBQStateObject

@end

#pragma mark - RBQChangeSetsObject

@interface RBQChangeSetsObject : NSObject

@property (strong, nonatomic) NSOrderedSet *cacheObjectsChangeSet;
@property (strong, nonatomic) NSOrderedSet *cacheSectionsChangeSet;
@property (strong, nonatomic) NSMapTable *cacheObjectToSafeObject;

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

@property (nonatomic, strong) NSOrderedSet *deletedSectionChanges;
@property (nonatomic, strong) NSOrderedSet *insertedSectionChanges;
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
        RLMRealm *cacheRealm = [RBQFetchedResultsController realmForCacheName:name];
        
        [cacheRealm beginWriteTransaction];
        [cacheRealm deleteAllObjects];
        [cacheRealm commitWriteTransaction];
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

+ (NSArray *)allCacheRealmPaths
{
    NSString *basePath = [RBQFetchedResultsController basePathForCaches];
    
    NSURL *baseURL = [[NSURL alloc] initFileURLWithPath:basePath isDirectory:YES];
    
    NSError *error = nil;
    NSArray *urlsInSyncCache =
    [[NSFileManager defaultManager] contentsOfDirectoryAtURL:baseURL
                                  includingPropertiesForKeys:@[NSURLIsDirectoryKey, NSURLNameKey]
                                                     options:0
                                                       error:&error];
    
    if (error) {
        NSLog(@"Error retrieving sync cache directories: %@", error.localizedDescription);
        
    }
    
    NSMutableArray *cachePaths = [NSMutableArray array];
    
    for (NSURL *url in urlsInSyncCache) {
        NSNumber *isDirectory = nil;
        NSError *error = nil;
        
        if (![url getResourceValue:&isDirectory
                            forKey:NSURLIsDirectoryKey
                             error:&error]) {
            
            NSLog(@"Error retrieving resource value: %@", error.localizedDescription);
        }
        
        if (isDirectory.boolValue) {
            NSString *name = nil;
            
            if (![url getResourceValue:&name
                                forKey:NSURLNameKey
                                 error:&error]) {
                
                NSLog(@"Error retrieving resource value: %@", error.localizedDescription);
            }
            else {
                // Directory name is filename with extension stripped
                NSString *cachePath = [RBQFetchedResultsController cachePathWithName:name];
                
                [cachePaths addObject:cachePath];
            }
        }
    }
    
    return cachePaths.copy;
}

#pragma mark - Private Class

// Create Realm instance for cache name
+ (RLMRealm *)realmForCacheName:(NSString *)cacheName
{
    NSURL *url = [NSURL fileURLWithPath:[RBQFetchedResultsController cachePathWithName:cacheName]];
    
    RLMRealmConfiguration *config = [RLMRealmConfiguration defaultConfiguration];
    config.fileURL = url;
    config.encryptionKey = nil;
    config.objectClasses = @[RBQControllerCacheObject.class, RBQObjectCacheObject.class, RBQSectionCacheObject.class];
    
    return [RLMRealm realmWithConfiguration:config error:nil];;
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
        [[NSFileManager defaultManager] createDirectoryAtPath:cachePath
                                  withIntermediateDirectories:NO
                                                   attributes:@{NSFileProtectionKey:NSFileProtectionNone}
                                                        error:&error];
        
        if (error) {
#ifdef DEBUG
            NSLog(@"FRC Cache Directory Creation Error: %@",error.localizedDescription);
#endif
        }
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
        [[NSFileManager defaultManager] createDirectoryAtPath:basePath
                                  withIntermediateDirectories:NO
                                                   attributes:@{NSFileProtectionKey:NSFileProtectionNone}
                                                        error:&error];
        
        if (error) {
#ifdef DEBUG
            NSLog(@"FRC Cache Directory Creation Error: %@",error.localizedDescription);
#endif
        }
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
        [[NSFileManager defaultManager] createDirectoryAtPath:cachePath
                                  withIntermediateDirectories:NO
                                                   attributes:@{NSFileProtectionKey:NSFileProtectionNone}
                                                        error:&error];
        
        if (error) {
#ifdef DEBUG
            NSLog(@"FRC Cache Directory Creation Error: %@",error.localizedDescription);
#endif
        }
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
    }
    
    return self;
}

- (BOOL)performFetch
{
    if ([self.delegate respondsToSelector:@selector(controllerWillPerformFetch:)]) {
        [self.delegate controllerWillPerformFetch:self];
    }
    
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
        
        // Only register for changes after the cache was created!
        [self registerChangeNotifications];
        
        if ([self.delegate respondsToSelector:@selector(controllerDidPerformFetch:)]) {
            [self.delegate controllerDidPerformFetch:self];
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
    
    [self unregisterChangeNotifications];
    
    [cacheRealm beginWriteTransaction];
    [cacheRealm deleteAllObjects];
    [cacheRealm commitWriteTransaction];
    
    [self performFetch];
    
    [self registerChangeNotifications];
}

- (RBQSafeRealmObject *)safeObjectAtIndexPath:(NSIndexPath *)indexPath
{
    RBQControllerCacheObject *cache = [self cache];
    
    if (indexPath.section < cache.sections.count) {
        
        RBQSectionCacheObject *section = cache.sections[indexPath.section];
        
        if (indexPath.row < section.objects.count) {
            
            RBQObjectCacheObject *cacheObject = section.objects[indexPath.row];
            
            RLMRealm *realm = self.fetchRequest.realm;
            
            // Call refresh to guarantee latest results
            [realm refresh];
            
            RLMObject *object =
            [RBQObjectCacheObject objectInRealm:realm
                                 forCacheObject:cacheObject];
            
            return [RBQSafeRealmObject safeObjectFromObject:object];
        }
    }
    
    return nil;
}

- (id)objectAtIndexPath:(NSIndexPath *)indexPath
{
    RBQControllerCacheObject *cache = [self cache];
    
    if (indexPath.section < cache.sections.count) {
        RBQSectionCacheObject *section = cache.sections[indexPath.section];
        
        if (indexPath.row < section.objects.count) {
            RBQObjectCacheObject *cacheObject = section.objects[indexPath.row];
            
            RLMRealm *realm = self.fetchRequest.realm;
            
            // Call refresh to guarantee latest results
            [realm refresh];
            
            return [RBQObjectCacheObject objectInRealm:realm
                                        forCacheObject:cacheObject];
        }
    }
    
    return nil;
}

- (NSIndexPath *)indexPathForSafeObject:(RBQSafeRealmObject *)safeObject
{
    RBQControllerCacheObject *cache = [self cache];
    
    if (cache) {
        RLMRealm *cacheRealm = cache.realm;
        
        // Get the string value of the primaryKeyValue
        NSString *primaryKeyStringValue = [NSString stringWithFormat:@"%@",safeObject.primaryKeyValue];
        
        RBQObjectCacheObject *cacheObject =
        [RBQObjectCacheObject objectInRealm:cacheRealm forPrimaryKey:primaryKeyStringValue];
        
        NSInteger sectionIndex = [cache.sections indexOfObject:cacheObject.section];
        NSInteger rowIndex = [cacheObject.section.objects indexOfObject:cacheObject];
        
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:rowIndex inSection:sectionIndex];
        
        return indexPath;
    }
    
    return nil;
}

- (NSIndexPath *)indexPathForObject:(RLMObjectBase *)object
{
    RBQControllerCacheObject *cache = [self cache];
    
    if (cache) {
        RLMRealm *cacheRealm = cache.realm;
        
        RBQObjectCacheObject *cacheObject =
        [RBQObjectCacheObject cacheObjectInRealm:cacheRealm
                                       forObject:object];
        
        NSInteger sectionIndex = [cache.sections indexOfObject:cacheObject.section];
        NSInteger rowIndex = [cacheObject.section.objects indexOfObject:cacheObject];
        
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:rowIndex inSection:sectionIndex];
        
        return indexPath;
    }
    
    return nil;
}

- (NSInteger)numberOfRowsForSectionIndex:(NSInteger)index
{
    RBQControllerCacheObject *cache = [self cache];
    
    if (index < cache.sections.count) {
        RBQSectionCacheObject *section = cache.sections[index];
        
        return section.objects.count;
    }
    
    return 0;
}

- (NSInteger)numberOfSections
{
    RBQControllerCacheObject *cache = [self cache];
    
    if (cache) {
        return cache.sections.count;
    }
    
    return 0;
}

- (NSString *)titleForHeaderInSection:(NSInteger)section
{
    RBQControllerCacheObject *cache = [self cache];
    
    if (cache) {
        
        if (section < cache.sections.count) {
            RBQSectionCacheObject *sectionInfo = cache.sections[section];
            
            return sectionInfo.name;
        }
    }
    
    return @"";
}

- (NSUInteger)sectionIndexForSectionName:(NSString *)sectionName
{
    RBQControllerCacheObject *cache = [self cache];
    
    if (cache) {
        
        RLMResults *sectionWithName = [cache.sections objectsWhere:@"name == %@",sectionName];
        
        RBQSectionCacheObject *section = sectionWithName.firstObject;
        
        if (section) {
            
            return [cache.sections indexOfObject:section];
        }
    }
    
    return NSNotFound;
}

- (void)updateFetchRequest:(RBQFetchRequest *)fetchRequest
        sectionNameKeyPath:(NSString *)sectionNameKeyPath
            andPerformFetch:(BOOL)performFetch
{
    @synchronized(self) {
        // Turn off change notifications since we are replacing fetch request
        // Change notifications will be re-registered if performFetch is called
        [self unregisterChangeNotifications];
        
        // Updating the fetch request will force rebuild of cache automatically
        _sectionNameKeyPath = sectionNameKeyPath;
        _fetchRequest = fetchRequest;
        
        if (performFetch) {
            // Only performFetch if the change processing is finished
            [self performFetch];
        }
    }
}

#pragma mark - Getters

- (id<RLMCollection>)fetchedObjects
{
    if (self.fetchRequest) {
        return [self.fetchRequest fetchObjects];
    }
    
    return nil;
}

- (NSArray<NSString *> *)sectionIndexTitles
{
    RBQControllerCacheObject *cache = [self cache];
    
    if (cache) {
        NSArray *titles = [cache.sections valueForKey:@"name"];
        
        return titles;
    }
    
    return nil;
}

#pragma mark - Private

- (void)dealloc
{
    // Remove the notifications
    [self unregisterChangeNotifications];
}

- (NSSet *)safeObjectsFromChanges:(NSArray<NSNumber *> *)changes
                   withCollection:(id<RLMCollection>)collection
                      isInsertion:(BOOL)isInsertion
{
    NSMutableSet *set = [NSMutableSet setWithCapacity:changes.count];
    
    RLMRealm *cacheRealm = [self cacheRealm];
    
    for (NSNumber *index in changes) {
        RBQSafeRealmObject *safeObject = nil;
        
        if (isInsertion) {
            RLMObject *object = [collection objectAtIndex:index.unsignedIntegerValue];
            safeObject = [RBQSafeRealmObject safeObjectFromObject:object];
        }
        else {
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"firstObjectIndex <= %@ AND lastObjectIndex >= %@", index, index];
            RLMResults *sections = [RBQSectionCacheObject objectsInRealm:cacheRealm withPredicate:predicate];
            RBQSectionCacheObject *section = sections.firstObject;
            NSUInteger row = index.unsignedIntegerValue - section.firstObjectIndex;
            RBQObjectCacheObject *objectCache = [section.objects objectAtIndex:row];
            safeObject = [[RBQSafeRealmObject alloc] initWithClassName:objectCache.className
                                                       primaryKeyValue:objectCache.primaryKeyValue
                                                        primaryKeyType:(RLMPropertyType)objectCache.primaryKeyType
                                                                 realm:collection.realm];
        }
        
        [set addObject:safeObject];
    }
    
    return set.copy;
}

// Register the change notification from RBQRealmNotificationManager
// Is no-op if the change notifications are already registered
- (void)registerChangeNotifications
{
    typeof(self) __weak weakSelf = self;
    
    // Setup run loop
    if (!self.notificationRunLoop) {
        dispatch_semaphore_t sem = dispatch_semaphore_create(0);
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            CFRunLoopPerformBlock(CFRunLoopGetCurrent(), kCFRunLoopDefaultMode, ^{
                weakSelf.notificationRunLoop = [NSRunLoop currentRunLoop];
                
                dispatch_semaphore_signal(sem);
            });
            
            CFRunLoopRun();
        });
        
        dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    }
    
    CFRunLoopPerformBlock(self.notificationRunLoop.getCFRunLoop, kCFRunLoopDefaultMode, ^{
        if (weakSelf.notificationToken) {
            [weakSelf.notificationToken stop];
            weakSelf.notificationToken = nil;
            weakSelf.notificationCollection = nil;
        }
        
        weakSelf.notificationCollection = weakSelf.fetchRequest.fetchObjects;
        weakSelf.notificationToken = [weakSelf.notificationCollection
                                      addNotificationBlock:^(id<RLMCollection>  _Nullable collection,
                                                             RLMCollectionChange * _Nullable change,
                                                             NSError * _Nullable error) {
                                          if (!error &&
                                              change) {
                                              // Create the change sets
                                              NSSet *addedSafeObjects = [weakSelf safeObjectsFromChanges:change.insertions withCollection:collection isInsertion:YES];
                                              NSSet *deletedSafeObjects = [weakSelf safeObjectsFromChanges:change.deletions withCollection:collection isInsertion:NO];
                                              NSSet *changedSafeObjects = [weakSelf safeObjectsFromChanges:change.modifications withCollection:collection isInsertion:NO];
                                              
                                              [weakSelf calculateChangesWithAddedSafeObjects:addedSafeObjects
                                                                          deletedSafeObjects:deletedSafeObjects
                                                                          changedSafeObjects:changedSafeObjects
                                                                                       realm:collection.realm];
                                          }
                                      }];
    });
    
    CFRunLoopWakeUp(self.notificationRunLoop.getCFRunLoop);
}

- (void)unregisterChangeNotifications
{
    // Remove the notifications
    if (self.notificationToken) {
        [self.notificationToken stop];
        self.notificationToken = nil;
    }
    
    // Stop the run loop
    if (self.notificationRunLoop) {
        CFRunLoopStop(self.notificationRunLoop.getCFRunLoop);
        self.notificationRunLoop = nil;
    }
}

#pragma mark - Change Calculations

- (void)calculateChangesWithAddedSafeObjects:(NSSet *)addedSafeObjects
                          deletedSafeObjects:(NSSet *)deletedSafeObjects
                          changedSafeObjects:(NSSet *)changedSafeObjects
                                       realm:(RLMRealm *)realm
{
    @synchronized(self) {
#ifdef DEBUG
        NSAssert(addedSafeObjects, @"Added safe objects can't be nil");
        NSAssert(deletedSafeObjects, @"Deleted safe objects can't be nil");
        NSAssert(changedSafeObjects, @"Changed safe objects can't be nil");
        NSAssert(realm, @"Realm can't be nil");
#endif
        /**
         *  If we are not on the main thread then use a semaphore
         *  to prevent condition where subsequent processing runs
         *  before the async delegate calls complete on main thread
         */
        BOOL useSem = NO;
        
        dispatch_semaphore_t sem = dispatch_semaphore_create(0);
        
        if (![NSThread isMainThread]) {
            useSem = YES;
        }
        
        typeof(self) __weak weakSelf = self;
        
        /**
         *  Refresh both the cache and main Realm.
         *
         *  NOTE: must use helper refresh method, so that
         *  we prevent acting on the duplicate notification
         *  triggered by the refresh.
         *
         *  This is a requirement for any refresh called
         *  synchronously from a RLMRealmDidChangeNotification.
         */
        RLMRealm *cacheRealm = [self cacheRealm];
        
        RBQControllerCacheObject *cache = [self cacheInRealm:cacheRealm];
        
#ifdef DEBUG
        NSAssert(cache, @"Cache can't be nil!");
#endif
        
        RBQStateObject *state = [self createStateObjectWithFetchRequest:self.fetchRequest
                                                                  realm:realm
                                                                  cache:cache
                                                             cacheRealm:cacheRealm];
        
        RBQChangeSetsObject *changeSets =
        [self createChangeSetsWithAddedSafeObjects:addedSafeObjects
                                deletedSafeObjects:deletedSafeObjects
                                changedSafeObjects:changedSafeObjects
                                             state:state];
        
        
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

        if ([self.delegate respondsToSelector:@selector(controllerWillChangeContent:)]) {

            [self runOnMainThread:^(){
                [weakSelf.delegate controllerWillChangeContent:weakSelf];
            }];
        }

        [state.cacheRealm beginWriteTransaction];
        
        // Create Object To Gather Up Derived Changes
        RBQDerivedChangesObject *derivedChanges = [self deriveChangesWithChangeSets:changeSets
                                                                     sectionChanges:sectionChanges
                                                                              state:state];
#ifdef DEBUG
        NSLog(@"%lu Derived Inserted Sections",(unsigned long)derivedChanges.insertedSectionChanges.count);
        NSLog(@"%lu Derived Deleted Sections",(unsigned long)derivedChanges.deletedSectionChanges.count);
        NSLog(@"%lu Derived Added Objects",(unsigned long)derivedChanges.insertedObjectChanges.count);
        NSLog(@"%lu Derived Deleted Objects",(unsigned long)derivedChanges.deletedObjectChanges.count);
        NSLog(@"%lu Derived Moved Objects",(unsigned long)derivedChanges.movedObjectChanges.count);
#endif
        
        // Apply Derived Changes To Cache
        [self applyDerivedChangesToCache:derivedChanges
                                   state:state];
        
        [state.cacheRealm commitWriteTransaction];
        
        [self runOnMainThread:^(){
            if ([weakSelf.delegate respondsToSelector:@selector(controllerDidChangeContent:)]) {
                [weakSelf.delegate controllerDidChangeContent:weakSelf];
            }
            
            if (useSem) {
                dispatch_semaphore_signal(sem);
            }
        }];
        
        if (useSem) {
            dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
        }
    }
}

- (void)applyDerivedChangesToCache:(RBQDerivedChangesObject *)derivedChanges
                             state:(RBQStateObject *)state
{
#ifdef DEBUG
    NSAssert(derivedChanges, @"Derived changes can't be nil!");
    NSAssert(state, @"State can't be nil!");
#endif
    
    // Apply Section Changes To Cache (deletes in reverse order, then inserts)
    for (NSOrderedSet *sectionChanges in @[derivedChanges.deletedSectionChanges,
                                           derivedChanges.insertedSectionChanges]) {
        
        for (RBQSectionChangeObject *sectionChange in sectionChanges) {
            
            if (sectionChange.changeType == NSFetchedResultsChangeDelete) {
                
#ifdef DEBUG
                NSAssert(sectionChange.previousIndex.unsignedIntegerValue < state.cache.sections.count, @"Attemting to delete index that is already gone!");
#endif
                // Remove the section from Realm cache
                [state.cache.sections removeObjectAtIndex:sectionChange.previousIndex.unsignedIntegerValue];
            }
            else if (sectionChange.changeType == NSFetchedResultsChangeInsert) {
                
#ifdef DEBUG
                NSAssert(sectionChange.updatedIndex.unsignedIntegerValue <= state.cache.sections.count, @"Attemting to insert at index beyond bounds!");
#endif
                // Add the section to the cache
                [state.cache.sections insertObject:sectionChange.section
                                           atIndex:sectionChange.updatedIndex.unsignedIntegerValue];
            }
        }
    }
    
    // Apply Object Changes To Cache (Must apply in correct order!)
    for (NSOrderedSet *objectChanges in @[derivedChanges.deletedObjectChanges,
                                          derivedChanges.insertedObjectChanges,
                                          derivedChanges.movedObjectChanges]) {
        
        for (RBQObjectChangeObject *objectChange in objectChanges) {
            
            if (objectChange.changeType == NSFetchedResultsChangeDelete) {
                
                // Remove the object from the section
                RBQSectionCacheObject *section = objectChange.previousCacheObject.section;
                
                [section.objects removeObjectAtIndex:objectChange.previousIndexPath.row];
                
                // Remove the object
                [state.cacheRealm deleteObject:objectChange.previousCacheObject];
            }
            else if (objectChange.changeType == NSFetchedResultsChangeInsert) {
                // Insert the object
                [state.cacheRealm addObject:objectChange.updatedCacheObject];
                
                // Add the object to the objects array and not just to the Realm!
                [state.cache.objects addObject:objectChange.updatedCacheObject];
                
                // Get the section and add it to it
                RBQSectionCacheObject *section =
                [RBQSectionCacheObject objectInRealm:state.cacheRealm
                                       forPrimaryKey:objectChange.updatedCacheObject.sectionKeyPathValue];
                
#ifdef DEBUG
                NSAssert(objectChange.updatedIndexpath.row <= section.objects.count, @"Attemting to insert at index beyond bounds!");
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
                
                // Add the object to the objects array and not just to the Realm!
                [state.cache.objects addObject:objectChange.updatedCacheObject];
                
                // Get the section and add it to it
                RBQSectionCacheObject *section =
                [RBQSectionCacheObject objectInRealm:state.cacheRealm
                                       forPrimaryKey:objectChange.updatedCacheObject.sectionKeyPathValue];
                
#ifdef DEBUG
                NSAssert(objectChange.updatedIndexpath.row <= section.objects.count, @"Attemting to insert at index beyond bounds!");
#endif
                
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
    id<RLMCollection> fetchResults = [fetchRequest fetchObjects];
    
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
            
            section.firstObjectIndex = 0;
        }
        
        NSUInteger count = 0;
        
        for (RLMObject *object in fetchResults) {
            
            if (sectionNameKeyPath) {
                
                // Check your sectionNameKeyPath if a crash occurs...
                NSString *sectionTitle = [object valueForKeyPath:sectionNameKeyPath];
                
                // New Section Found --> Process It
                if (![sectionTitle isEqualToString:currentSectionTitle]) {
                    
                    // If we already gathered up the section objects, then save them
                    if (section.objects.count > 0) {
                        
                        section.lastObjectIndex = count - 1; // We advanced already so we need to save previous index
                        
                        // Add the section to Realm
                        [cacheRealm addOrUpdateObject:section];
                        
                        // Add the section to the controller cache
                        [controllerCache.sections addObject:section];
                    }
                    
                    // Keep track of the section title so we create one section cache per value
                    currentSectionTitle = sectionTitle;
                    
                    // Reset the section object array
                    section = [RBQSectionCacheObject cacheWithName:currentSectionTitle];
                    
                    section.firstObjectIndex = count;
                }
            }
            
            // Save the final section (or if not using sections, the only section)
            if (count == fetchResults.count - 1) {
                
                section.lastObjectIndex = count; // Set the last object index
                
                // Add the section to Realm
                [cacheRealm addOrUpdateObject:section];
                
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
            
            // Keep track of the count
            count ++;
        }
        
        // Set the section name key path, if available
        if (sectionNameKeyPath) {
            controllerCache.sectionNameKeyPath = sectionNameKeyPath;
        }
        
        // Add cache to Realm
        [cacheRealm addOrUpdateObject:controllerCache];
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
    stateObject.fetchResults = [fetchRequest fetchObjects];
    
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
    NSMapTable *cacheObjectToSafeObject = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsStrongMemory valueOptions:NSPointerFunctionsStrongMemory];
    
    for (NSSet *changedObjects in @[addedSafeObjects, deletedSafeObjects, changedSafeObjects]) {
        
        for (RBQSafeRealmObject *safeObject in changedObjects) {
            
            // Get the section titles in change set
            // Attempt to get the object from non-cache Realm
            RLMObject *object = [RBQSafeRealmObject objectfromSafeObject:safeObject];
            
            // Get the string value of the primaryKeyValue
            NSString *primaryKeyStringValue = [NSString stringWithFormat:@"%@",safeObject.primaryKeyValue];
            
            // If the changed object doesn't match the predicate and
            // was not already in the cache, then skip it
            if (![self.fetchRequest evaluateObject:object] &&
                ![RBQObjectCacheObject objectInRealm:state.cacheRealm
                                       forPrimaryKey:primaryKeyStringValue]) {
                    continue;
                }
            
            NSString *sectionTitle = nil;
            
            if (object &&
                self.sectionNameKeyPath) {
                sectionTitle = [object valueForKeyPath:self.sectionNameKeyPath];
            }
            else if (self.sectionNameKeyPath) {
                RBQObjectCacheObject *oldCacheObject =
                [RBQObjectCacheObject objectInRealm:state.cacheRealm
                                      forPrimaryKey:primaryKeyStringValue];
                
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
        changeSets.cacheObjectToSafeObject = cacheObjectToSafeObject;
        
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
        
        id<RLMCollection> sectionResults = nil;
        
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
        else {
            if ([state.cache.sections indexOfObject:section] != NSNotFound) {
                [deletedSections addObject:section];
            }
        }
    }
    
    // Now sort the sections (sort inserts to be ascending)
    NSSortDescriptor *sortByFirstIndex =
    [NSSortDescriptor sortDescriptorWithKey:@"firstObjectIndex" ascending:YES];
    [newSections sortUsingDescriptors:@[sortByFirstIndex]];
    
    // Sort the deleted sections
    NSSortDescriptor *descendingDeleteSort =
    [NSSortDescriptor sortDescriptorWithKey:@"firstObjectIndex" ascending:NO];
    [deletedSections sortUsingDescriptors:@[descendingDeleteSort]];
    
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
    // No need to refresh on the non-cache Realm, since this causes recursion
    // (refresh sends RLMRealmDidChangeNotification causing FRC processing to start anew)
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
    NSAssert(derivedChanges.deletedSectionChanges, @"Deleted sections changes array can't be nil!");
    NSAssert(derivedChanges.insertedSectionChanges, @"Inserted sections changes array can't be nil!");
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
    
    NSMutableOrderedSet *deletedSectionChanges = [[NSMutableOrderedSet alloc] initWithCapacity:sectionChanges.deletedCacheSections.count];
    NSMutableOrderedSet *insertedSectionChanges = [[NSMutableOrderedSet alloc] initWithCapacity:sectionChanges.insertedCacheSections.count];
    
    typeof(self) __weak weakSelf = self;
    
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
            [self runOnMainThread:^(){
                [weakSelf.delegate controller:weakSelf
                             didChangeSection:sectionInfo
                                      atIndex:oldSectionIndex
                                forChangeType:NSFetchedResultsChangeDelete];
            }];
        }
        
        // Create the section change object
        RBQSectionChangeObject *sectionChange = [[RBQSectionChangeObject alloc] init];
        sectionChange.previousIndex = @(oldSectionIndex);
        sectionChange.section = section;
        sectionChange.changeType = NSFetchedResultsChangeDelete;
        
        [deletedSectionChanges addObject:sectionChange];
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
            [self runOnMainThread:^(){
                [weakSelf.delegate controller:weakSelf
                             didChangeSection:sectionInfo
                                      atIndex:newSectionIndex
                                forChangeType:NSFetchedResultsChangeInsert];
            }];
        }
        
        // Create the section change object
        RBQSectionChangeObject *sectionChange = [[RBQSectionChangeObject alloc] init];
        sectionChange.updatedIndex = @(newSectionIndex);
        sectionChange.section = section;
        sectionChange.changeType = NSFetchedResultsChangeInsert;
        
        [insertedSectionChanges addObject:sectionChange];
    }
    
    // Sort the changes (Deleted is reverse sort)
    [deletedSectionChanges sortUsingComparator:^NSComparisonResult(RBQSectionChangeObject *sec1,
                                                                   RBQSectionChangeObject *sec2) {
        // Compare the index (reverse sort)
        return [sec2.previousIndex compare:sec1.previousIndex];
    }];
    
    [insertedSectionChanges sortUsingComparator:^NSComparisonResult(RBQSectionChangeObject *sec1,
                                                                    RBQSectionChangeObject *sec2) {
        // Compare the index
        return [sec1.updatedIndex compare:sec2.updatedIndex];
    }];
    
    derivedChanges.deletedSectionChanges = deletedSectionChanges.copy;
    derivedChanges.insertedSectionChanges = insertedSectionChanges.copy;
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
    
    typeof(self) __weak weakSelf = self;
    
    // We will first process to find inserts/deletes
    NSMutableOrderedSet *deletedObjectChanges = [[NSMutableOrderedSet alloc] init];
    NSMutableOrderedSet *insertedObjectChanges = [[NSMutableOrderedSet alloc] init];
    
    NSMutableDictionary *deletedObjectChangesBySection = [[NSMutableDictionary alloc] init];
    NSMutableDictionary *insertedObjectChangesBySection = [[NSMutableDictionary alloc] init];
    
    /**
     *  We will collect any cache objects that aren't inserts/deletes to
     *  process them in a second batch to find moves/updates
     */
    NSMutableSet *moveOrUpdateObjectChanges = [[NSMutableSet alloc] init];
    
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
                [self runOnMainThread:^(){
                    [weakSelf.delegate controller:weakSelf
                                  didChangeObject:safeObject
                                      atIndexPath:objectChange.previousIndexPath
                                    forChangeType:NSFetchedResultsChangeDelete
                                     newIndexPath:nil];
                }];
            }
            
            objectChange.changeType = NSFetchedResultsChangeDelete;
            
            [deletedObjectChanges addObject:objectChange];
            
            NSMutableOrderedSet *deletedChangesInSection =
            [deletedObjectChangesBySection objectForKey:@(objectChange.previousIndexPath.section)];
            
            if (!deletedChangesInSection) {
                deletedChangesInSection = [[NSMutableOrderedSet alloc] init];
                
                [deletedObjectChangesBySection setObject:deletedChangesInSection
                                                  forKey:@(objectChange.previousIndexPath.section)];
            }
            
            [deletedChangesInSection addObject:objectChange];
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
                [self runOnMainThread:^(){
                    [weakSelf.delegate controller:weakSelf
                                  didChangeObject:safeObject
                                      atIndexPath:nil
                                    forChangeType:NSFetchedResultsChangeInsert
                                     newIndexPath:objectChange.updatedIndexpath];
                }];
            }
            objectChange.changeType = NSFetchedResultsChangeInsert;
            
            [insertedObjectChanges addObject:objectChange];
            
            NSMutableOrderedSet *insertedChangesInSection =
            [insertedObjectChangesBySection objectForKey:@(objectChange.updatedIndexpath.section)];
            
            if (!insertedChangesInSection) {
                insertedChangesInSection = [[NSMutableOrderedSet alloc] init];
                
                [insertedObjectChangesBySection setObject:insertedChangesInSection
                                                   forKey:@(objectChange.updatedIndexpath.section)];
            }

            [insertedChangesInSection addObject:objectChange];
        }
        // For all objectChanges that are not inserts/deletes, store them to process next
        else {
            [moveOrUpdateObjectChanges addObject:objectChange];
        }
    }
    
    // Sort the collections (deleted reverse sort)
    [deletedObjectChanges sortUsingComparator:^NSComparisonResult(RBQObjectChangeObject *obj1,
                                                                  RBQObjectChangeObject *obj2) {
        // Compare the indexPaths (reverse sort)
        return [obj2.previousIndexPath compare:obj1.previousIndexPath];
    }];
    
    for (NSNumber *key in deletedObjectChangesBySection) {
        NSMutableOrderedSet *deletedChangesInSection = deletedObjectChangesBySection[key];
        
        [deletedChangesInSection sortUsingComparator:^NSComparisonResult(RBQObjectChangeObject *obj1,
                                                                         RBQObjectChangeObject *obj2) {
            // Compare the indexPaths (reverse sort)
            return [obj2.previousIndexPath compare:obj1.previousIndexPath];
        }];
    }
    
    [insertedObjectChanges sortUsingComparator:^NSComparisonResult(RBQObjectChangeObject *obj1,
                                                                   RBQObjectChangeObject *obj2) {
        // Compare the indexPaths
        return [obj1.updatedIndexpath compare:obj2.updatedIndexpath];
    }];
    
    for (NSNumber *key in insertedObjectChangesBySection) {
        NSMutableOrderedSet *insertedChangesInSection = insertedObjectChangesBySection[key];
        
        [insertedChangesInSection sortUsingComparator:^NSComparisonResult(RBQObjectChangeObject *obj1,
                                                                          RBQObjectChangeObject *obj2) {
            // Compare the indexPaths
            return [obj1.updatedIndexpath compare:obj2.updatedIndexpath];
        }];
    }
    
    NSMutableOrderedSet *movedObjectChanges = [[NSMutableOrderedSet alloc] init];
    
    /**
     *  Now we will process the remaining items to identify moves/updates
     *
     *  To accurately find moves, we need to calculate the absolute change to the section and row
     *
     *  To identify absolute changes, we need to figure out the relative changes to sections and rows
     *
     *  Initially, relative section changes were calculated, but in practice UITableview just wants
     *  section changes reported as moves. However, there is a unique situation where the indexPath
     *  doesn't change on an object, but the section was deleted and inserted on itself, so we use
     *  the section changes to catch this scenario.
     */
    
    
    /**
     *  First we will create two collections: the inserted section indexes and deleted section indexes
     *
     *  Both of these will be used for any relative section change checking
     *
     *  Note: this might not need to be sorted as a potential performance improvement (legacy
     *  from calculating relative section changes, but leaving aside for now).
     */
    
    NSMutableOrderedSet *insertedSectionIndexes =
    [[NSMutableOrderedSet alloc] initWithCapacity:sectionChanges.insertedCacheSections.count];
    
    for (RBQSectionCacheObject *sectionCache in sectionChanges.insertedCacheSections) {
        NSNumber *index = @([sectionChanges.sortedNewCacheSections indexOfObject:sectionCache]);
        
        [insertedSectionIndexes addObject:index];
    }
    
    // Sort the indexes
    [insertedSectionIndexes sortUsingComparator:^NSComparisonResult(NSNumber *num1,
                                                                    NSNumber *num2) {
        // Compare the NSNumbers
        return [num1 compare:num2];
    }];
    
    NSMutableOrderedSet *deletedSectionIndexes =
    [[NSMutableOrderedSet alloc] initWithCapacity:sectionChanges.deletedCacheSections.count];
    
    for (RBQSectionCacheObject *sectionCache in sectionChanges.deletedCacheSections) {
        NSNumber *index = @([sectionChanges.oldCacheSections indexOfObject:sectionCache]);
        
        [deletedSectionIndexes addObject:index];
    }
    
    // Sort the indexes
    [deletedSectionIndexes sortUsingComparator:^NSComparisonResult(NSNumber *num1,
                                                                   NSNumber *num2) {
        // Compare the NSNumbers
        return [num1 compare:num2];
    }];
    
    /**
     *  Now that we have the inserted/deleted section index collections and
     *  the inserted/deleted objectChange collections, we can process the remaining
     *  objectChanges to accurately identify moves
     */
    
    for (RBQObjectChangeObject *objectChange in moveOrUpdateObjectChanges) {
        
        /**
         *  Since we didn't find a section change, now we have to get
         *  the relative row changes for the section
         */
        NSOrderedSet *insertedObjectChangesForSection =
        [insertedObjectChangesBySection objectForKey:@(objectChange.updatedIndexpath.section)];
        
        NSUInteger rowInserts = 0;
        
        if (insertedObjectChangesForSection) {
            /**
             *  Get the number of row inserts that occurred
             *  before the updated indexPath
             *
             *  We calculate this by asking for the index if
             *  we were to insert object into the insert collection
             */
            NSRange sortRangeRowInserts = NSMakeRange(0, insertedObjectChanges.count);
            rowInserts =
            [insertedObjectChanges indexOfObject:objectChange
                                   inSortedRange:sortRangeRowInserts
                                         options:NSBinarySearchingInsertionIndex
                                 usingComparator:^NSComparisonResult(RBQObjectChangeObject *obj1,
                                                                     RBQObjectChangeObject *obj2) {
                                     // Compare the indexPaths
                                     return [obj1.updatedIndexpath compare:obj2.updatedIndexpath];
                                 }];
        }
        
        NSOrderedSet *deletedObjectChangesForSection =
        [deletedObjectChangesBySection objectForKey:@(objectChange.previousIndexPath.section)];
        
        NSUInteger rowDeletes = 0;
        
        if (deletedObjectChangesForSection) {
            /**
             *  Get the number of row deletes that occurred
             *  before the updated indexPath
             *
             *  We calculate this by asking for the index if
             *  we were to insert object into the delete collection
             */
            NSRange sortRangeRowDeletes = NSMakeRange(0, deletedObjectChanges.count);
            rowDeletes =
            [deletedObjectChanges indexOfObject:objectChange
                                  inSortedRange:sortRangeRowDeletes
                                        options:NSBinarySearchingInsertionIndex
                                usingComparator:^NSComparisonResult(RBQObjectChangeObject *obj1,
                                                                    RBQObjectChangeObject *obj2) {
                                    // Compare the indexPaths
                                    return [obj1.previousIndexPath compare:obj2.previousIndexPath];
                                }];
        }
        
        NSInteger relativeRowChange = rowInserts - rowDeletes;
        
        /**
         *  If an object is moving from one section to another,
         *  but that section index stays the same this needs to be
         *  reported as a move and not an update (the indexPath's are
         *  the same, but UITableView wants a move reported).
         */
        BOOL objectSectionReplacedItself = NO;
        
        if ([objectChange.updatedIndexpath compare:objectChange.previousIndexPath] == NSOrderedSame &&
            ([insertedSectionIndexes containsObject:@(objectChange.updatedIndexpath.section)] ||
             [deletedSectionIndexes containsObject:@(objectChange.updatedIndexpath.section)])) {
                
                objectSectionReplacedItself = YES;
            }
        
        /**
         *  Now that we have the relative row change, we can identify if there
         *  was an absolute change and report the move.
         
         *  Also report move if the section change replaced itself
         *  (i.e. indexPath is the same, but we deleted and inserted
         *  a section at the same index)
         *
         *  Report a move if the object changes section (even if relative)
         */
        if (([objectChange.updatedIndexpath compare:objectChange.previousIndexPath] != NSOrderedSame &&
             (objectChange.updatedIndexpath.row - objectChange.previousIndexPath.row) != relativeRowChange) ||
            objectChange.updatedIndexpath.section != objectChange.previousIndexPath.section ||
            objectSectionReplacedItself) {
            
            RBQSafeRealmObject *safeObject =
            [changeSets.cacheObjectToSafeObject objectForKey:objectChange.previousCacheObject];
            
#ifdef DEBUG
            NSAssert(safeObject, @"Safe object can't be nil!");
#endif
            
            if ([self.delegate respondsToSelector:
                 @selector(controller:didChangeObject:atIndexPath:forChangeType:newIndexPath:)])
            {
                [self runOnMainThread:^(){
                    [weakSelf.delegate controller:weakSelf
                                  didChangeObject:safeObject
                                      atIndexPath:objectChange.previousIndexPath
                                    forChangeType:NSFetchedResultsChangeMove
                                     newIndexPath:objectChange.updatedIndexpath];
                }];
            }
            
            objectChange.changeType = NSFetchedResultsChangeMove;
            
            [movedObjectChanges addObject:objectChange];
        }
        /**
         *  Finally, if the objectChange wasn't an absolute section change or an
         *  absolute row change, we just report it as an update
         */
        else {
            RBQSafeRealmObject *safeObject =
            [changeSets.cacheObjectToSafeObject objectForKey:objectChange.previousCacheObject];
            
#ifdef DEBUG
            NSAssert(safeObject, @"Safe object can't be nil!");
#endif
            
            if ([self.delegate respondsToSelector:
                 @selector(controller:didChangeObject:atIndexPath:forChangeType:newIndexPath:)])
            {
                [self runOnMainThread:^(){
                    [weakSelf.delegate controller:weakSelf
                                  didChangeObject:safeObject
                                      atIndexPath:objectChange.previousIndexPath
                                    forChangeType:NSFetchedResultsChangeUpdate
                                     newIndexPath:objectChange.updatedIndexpath];
                }];
            }
        }
    }
    
    // Sort the moved object changes by updated indexPath
    [movedObjectChanges sortUsingComparator:^NSComparisonResult(RBQObjectChangeObject *obj1,
                                                                RBQObjectChangeObject *obj2) {
        // Compare the indexPaths
        return [obj1.updatedIndexpath compare:obj2.updatedIndexpath];
    }];
    
    derivedChanges.deletedObjectChanges = deletedObjectChanges.copy;
    derivedChanges.insertedObjectChanges = insertedObjectChanges.copy;
    derivedChanges.movedObjectChanges = movedObjectChanges.copy;
}

#pragma mark - Helpers

// Create instance of Realm for internal cache
- (RLMRealm *)cacheRealm
{
    if (self.cacheName) {

        if ([NSThread isMainThread] &&
            self.realmForMainThread) {
            
            return self.realmForMainThread;
        }
        
        RLMRealm *realm = [RBQFetchedResultsController realmForCacheName:self.cacheName];
        
        if ([NSThread isMainThread]) {
            
            self.realmForMainThread = realm;
        }
        
        return realm;
    }
    else {
        RLMRealmConfiguration *inMemoryConfiguration = [RLMRealmConfiguration defaultConfiguration];
        inMemoryConfiguration.inMemoryIdentifier = [self nameForFetchRequest:self.fetchRequest];
        inMemoryConfiguration.encryptionKey = nil;
        inMemoryConfiguration.objectClasses = @[RBQControllerCacheObject.class,
                                                RBQObjectCacheObject.class,
                                                RBQSectionCacheObject.class];
        
        RLMRealm *realm = [RLMRealm realmWithConfiguration:inMemoryConfiguration
                                                     error:nil];
        
        // Hold onto a strong reference so inMemory realm cache doesn't get deallocated
        // We don't use the cache since this is deprecated
        // If the realm path changed (new fetch request then hold onto the new one)
        if (!self.inMemoryRealm ||
            ![realm.configuration.fileURL.path.lastPathComponent isEqualToString:self.inMemoryRealm.configuration.fileURL.path.lastPathComponent]) {
            
            self.inMemoryRealm = realm;
        }
        
        return realm;
    }
    
    return nil;
}

// Retrieve internal cache
- (RBQControllerCacheObject *)cache
{
    RLMRealm *cacheRealm = [self cacheRealm];
    
    [cacheRealm refresh];
    
    RBQControllerCacheObject *cache = [self cacheInRealm:cacheRealm];
    
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

- (void)runOnMainThread:(void (^)())mainThreadBlock
{
    if ([NSThread isMainThread]) {
        mainThreadBlock();
    }
    else {
        dispatch_async(dispatch_get_main_queue(), mainThreadBlock);
    }
}

@end
