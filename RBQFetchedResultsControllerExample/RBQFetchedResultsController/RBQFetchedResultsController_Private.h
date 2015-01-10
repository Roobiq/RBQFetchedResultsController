//
//  RBQFetchedResultsController_Private.h
//  RBQFetchedResultsControllerExample
//
//  Created by Adam Fish on 1/9/15.
//  Copyright (c) 2015 Roobiq. All rights reserved.
//

#import "RBQFetchedResultsController.h"
#import "RBQRealmNotificationManager.h"
#import "RBQFetchedResultsControllerCacheObject.h"
#import "RBQSectionCacheObject.h"

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

#pragma mark - RBQChangeSet

@interface RBQChangeSet : NSObject

@property (strong, nonatomic) NSArray *cacheObjectsChangeSet;
@property (strong, nonatomic) NSArray *cacheSectionsChangeSet;
@property (strong, nonatomic) NSArray *oldCacheSections;
@property (strong, nonatomic) NSArray *sortedNewCacheSections;
@property (strong, nonatomic) NSArray *deletedCacheSections;
@property (strong, nonatomic) NSArray *insertedCacheSections;
@property (strong, nonatomic) NSArray *safeObjectsSet;

@property (strong, nonatomic) RLMRealm *realm;
@property (strong, nonatomic) RLMRealm *cacheRealm;
@property (strong, nonatomic) RLMResults *fetchResults;
@property (strong, nonatomic) RBQFetchedResultsControllerCacheObject *cache;

@end

#pragma mark - RBQSectionChange

@interface RBQSectionChange : NSObject

@property (strong, nonatomic) NSNumber *previousIndex;
@property (strong, nonatomic) NSNumber *updatedIndex;
@property (strong, nonatomic) RBQSectionCacheObject *section;
@property (assign, nonatomic) NSFetchedResultsChangeType changeType;

@end

#pragma mark - RBQObjectChange

@interface RBQObjectChange : NSObject

@property (strong, nonatomic) NSIndexPath *previousIndexPath;
@property (strong, nonatomic) NSIndexPath *updatedIndexpath;
@property (assign, nonatomic) NSFetchedResultsChangeType changeType;
@property (strong, nonatomic) RBQSafeRealmObject *object;
@property (strong, nonatomic) RBQFetchedResultsCacheObject *previousCacheObject;
@property (strong, nonatomic) RBQFetchedResultsCacheObject *updatedCacheObject;

// Create a RBQObjectChange
+ (instancetype)objectChangeWithCacheObject:(RBQFetchedResultsCacheObject *)cacheObject
                                  changeSet:(RBQChangeSet *)changeSet;

@end

#pragma mark - RBQFetchedResultsChanges

@interface RBQFetchedResultsChanges : NSObject

@property (nonatomic, strong) NSMutableArray *sectionChanges;
@property (nonatomic, strong) NSMutableArray *deletedObjectChanges;
@property (nonatomic, strong) NSMutableArray *insertedObjectChanges;
@property (nonatomic, strong) NSMutableArray *movedObjectChanges;

@end

#pragma mark - RBQFetchedResultsController

@interface RBQFetchedResultsController ()

@property (strong, nonatomic) RBQNotificationToken *notificationToken;

// Create Realm instance for cache name
+ (RLMRealm *)realmForCacheName:(NSString *)cacheName;

//  Create a file path for Realm cache with a given name
+ (NSString *)cachePathWithName:(NSString *)name;

// Retrieve results with an already created Realm instance
+ (RLMResults *)fetchResultsInRealm:(RLMRealm *)realm
                    forFetchRequest:(RBQFetchRequest *)fetchRequest;

// Register the change notification from RBQRealmNotificationManager
- (void)registerChangeNotification;

// Create the internal cache for a fetch request
- (void)createCacheWithRealm:(RLMRealm *)cacheRealm
                   cacheName:(NSString *)cacheName
             forFetchRequest:(RBQFetchRequest *)fetchRequest
          sectionNameKeyPath:(NSString *)sectionNameKeyPath;

#pragma mark - Create Internal Change Objects

// Create the internal RBQChange set to represent the changes reported
- (RBQChangeSet *)createChangeSetsWithAddedObjects:(NSArray *)addedSafeObjects
                                 deletedSafeObject:(NSArray *)deletedSafeObjects
                                changedSafeObjects:(NSArray *)changedSafeObjects
                                             realm:(RLMRealm *)realm;

// Update the RBQChange set to include the collections that represent section changes
- (void)updateChangeSetForSections:(RBQChangeSet *)changeSet;

#pragma mark - Helpers

// Helper to make sure NSIndexPath != NSMutableIndexPath
- (NSIndexPath *)keyForIndexPath:(NSIndexPath *)indexPath;

// Create instance of Realm for internal cache
- (RLMRealm *)cacheRealm;

// Retrieve internal cache
- (RBQFetchedResultsControllerCacheObject *)cache;

// Create a computed name for a fetch request
- (NSString *)nameForFetchRequest:(RBQFetchRequest *)fetchRequest;

@end
