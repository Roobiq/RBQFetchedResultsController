//
//  RBQFetchedResultsController.m
//  RBQFetchedResultsControllerTest
//
//  Created by Lauren Smith on 1/2/15.
//  Copyright (c) 2015 Roobiq. All rights reserved.
//

#import "RBQFetchedResultsController.h"
#import "RBQRealmNotificationManager.h"

#import <Realm/Realm.h>

@import UIKit;

#pragma mark - RBQFetchedResultsSectionInfo

@interface RBQFetchedResultsSectionInfo ()

- (instancetype)initWithName:(NSString *)name
                     objects:(NSArray *)objects;

@end

@implementation RBQFetchedResultsSectionInfo

- (instancetype)initWithName:(NSString *)name
                     objects:(NSArray *)objects
{
    self = [super init];
    
    if (self) {
        _objects = objects;
        _name = name;
        _numberOfObjects = objects.count;
    }
    
    return self;
}

#pragma mark - Equality

- (BOOL)isEqualToSectionInfo:(RBQFetchedResultsSectionInfo *)sectionInfo
{
    // if identical object
    if (self == sectionInfo) {
        return YES;
    }
    
    if ([sectionInfo isKindOfClass:[RBQFetchedResultsSectionInfo class]]) {
        return [_name isEqualToString:sectionInfo.name];
    }

    return NO;
}

- (BOOL)isEqual:(id)object
{
    if (_name) {
        return [self isEqualToSectionInfo:object];
    }
    else {
        return [super isEqual:object];
    }
}

- (NSUInteger)hash
{
    if (_name) {
        // modify the hash of our primary key value to avoid potential (although unlikely) collisions
        // (Adam -- is the point here to avoid collisions if sections names are the same? Because
        //  xor'ing with 1 still results in the same hash for matching names...)
        return [_name hash] ^ 1;
    }
    else {
        return [super hash];
    }
}

@end

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

// Queue to manage the reads and writes
@property (strong, nonatomic) dispatch_queue_t concurrentResultsQueue;

@end

#pragma mark - RBQFetchedResultsController

@implementation RBQFetchedResultsController

#pragma mark - Public

- (id)initWithFetchRequest:(RBQFetchRequest *)fetchRequest
        sectionNameKeyPath:(NSString *)sectionNameKeyPath
{
    self = [super init];
    
    if (self) {
        _fetchRequest = fetchRequest;
        _sectionNameKeyPath = sectionNameKeyPath;
        _concurrentResultsQueue = dispatch_queue_create(
            "com.Roobiq.RBQFetchedResultsController.fetchedResultsQueue",
            DISPATCH_QUEUE_CONCURRENT
        );
        
        [self registerChangeNotification];
    }
    
    return self;
}

- (BOOL)performFetch
{
    if (self.fetchRequest) {
        
        dispatch_barrier_sync(self.concurrentResultsQueue, ^{
            RLMResults *fetchResults = [self fetchResultsInRealm:self.fetchRequest.realm
                                                 forFetchRequest:self.fetchRequest];
            
            self.fetchedResultsObject =
                [self fetchedResultsObjectWithFetchResults:fetchResults
                                        sectionNameKeyPath:self.sectionNameKeyPath];
        });
        
        return YES;
    }
    
    @throw [NSException exceptionWithName:@"RBQException"
                                   reason:@"Unable to perform fetch; fetchRequest must be set."
                                 userInfo:nil];
    
    return NO;
}

- (RBQSafeRealmObject *)safeObjectAtIndexPath:(NSIndexPath *)indexPath
{
    return self.fetchedResultsObject.indexPathKeyMap[[self keyForIndexPath:indexPath]];
}

- (id)objectAtIndexPath:(NSIndexPath *)indexPath
{
    NSIndexPath *key = [self keyForIndexPath:indexPath];
    RBQSafeRealmObject *safeObject = self.fetchedResultsObject.indexPathKeyMap[key];
    return [safeObject RLMObject];
}

- (id)objectInRealm:(RLMRealm *)realm
        atIndexPath:(NSIndexPath *)indexPath
{
    NSIndexPath *key = [self keyForIndexPath:indexPath];
    RBQSafeRealmObject *safeObject = self.fetchedResultsObject.indexPathKeyMap[key];
    return [RBQSafeRealmObject objectInRealm:realm fromSafeObject:safeObject];
}

- (NSIndexPath *)indexPathForSafeObject:(RBQSafeRealmObject *)safeObject
{
    return self.fetchedResultsObject.objectKeyMap[safeObject];
}

- (NSIndexPath *)indexPathForObject:(RLMObject *)object
{
    RBQSafeRealmObject *safeObject = [RBQSafeRealmObject safeObjectFromObject:object];
    return self.fetchedResultsObject.objectKeyMap[safeObject];
}

#pragma mark - Getters

- (NSArray *)fetchedObjects
{
    return self.fetchedResultsObject.fetchedObjects;
}

- (NSArray *)sections
{
    return self.fetchedResultsObject.sections;
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
            RLMResults *sameRealmFetchResults = [self fetchResultsInRealm:realm
                                                          forFetchRequest:self.fetchRequest];
            
            NSUInteger sameRealmCount = sameRealmFetchResults.count;
            
            if (addedSafeObjects.count > 0 ||
                deletedSafeObjects.count > 0 ||
                changedSafeObjects.count > 0) {
                dispatch_barrier_async(self.concurrentResultsQueue, ^{
                    
                    NSLog(@"Processing notification");
                    RLMRealm *newRealm = self.fetchRequest.realm;
                    
                    if (deletedSafeObjects.count > 0) {
                        [newRealm refresh];
                    }
                    
                    // Get the new list of safe fetch objects
                    RLMResults *fetchResults = [self fetchResultsInRealm:newRealm
                                                         forFetchRequest:self.fetchRequest];
                    
                    NSUInteger newRealmCount = fetchResults.count;
                    
                    NSLog(@"Same realm count: %d", sameRealmCount);
                    NSLog(@"New realm count: %d", newRealmCount);
                    
                    RBQFetchedResultsObject *newFetchedResultsObject =
                    [self fetchedResultsObjectWithFetchResults:fetchResults
                                            sectionNameKeyPath:self.sectionNameKeyPath];
                    
                    // Is copy necessary here?
                    RBQFetchedResultsObject *oldFetchedResultsObject = self.fetchedResultsObject.copy;
                    
                    dispatch_sync(dispatch_get_main_queue(), ^{
                        if ([self.delegate respondsToSelector:@selector(controllerWillChangeContent:)])
                        {
                            [self.delegate controllerWillChangeContent:self];
                        }
                    });
                    
                    self.fetchedResultsObject = newFetchedResultsObject;
                    
                    // Identify section changes
                    [self identifySectionChangesFromLatestResults:newFetchedResultsObject
                                                      oldSections:oldFetchedResultsObject.sections];
                    
                    // Process changes, additions, deletions
                    // Run all three from "changed" logic to catch weird edge cases where what client
                    // reported isn't what fetch diff observers (eg, user reports deletion but we still
                    // see it in fetch). What we report to delegate has to match what
                    // UITableViewDataSource delegate methods report, so if user-reported changes don't
                    // match fetched results, stick with fetch.
                    for (NSArray *changedObjects in @[changedSafeObjects, addedSafeObjects, deletedSafeObjects]) {
                        [self identifyChangesFromLatestResults:newFetchedResultsObject
                                       oldFetchedResultsObject:oldFetchedResultsObject
                                        withChangedSafeObjects:changedObjects];
                    }
                    
                    /*
                     [self identifyChangesFromLatestResults:newFetchedResultsObject
                     oldFetchedResultsObject:oldFetchedResultsObject
                     withChangedSafeObjects:changedSafeObjects];
                     
                     [self identifyChangesFromLatestResults:newFetchedResultsObject
                     withAddedSafeObjects:addedSafeObjects];
                     
                     [self identifyChangesFromLatestResults:newFetchedResultsObject
                     oldFetchedResultsObject:oldFetchedResultsObject
                     withDeletedSafeObjects:deletedSafeObjects];
                     */
                    
                    
                    dispatch_sync(dispatch_get_main_queue(), ^{
                        NSLog(@"Added Safe Objects: %d", addedSafeObjects.count);
                        NSLog(@"Deleted Safe Objects: %d", deletedSafeObjects.count);
                        NSLog(@"Changed Safe Objects: %d", changedSafeObjects.count);
                        
                        if ([self.delegate respondsToSelector:@selector(controllerDidChangeContent:)]) {
                            [self.delegate controllerDidChangeContent:self];
                        }
                    });
                    NSLog(@"Processed notification");
                });
            }
    }];
}

- (void)identifySectionChangesFromLatestResults:(RBQFetchedResultsObject *)newFetchedResultsObject
                                    oldSections:(NSArray *)oldSections
{
    if (newFetchedResultsObject.sections.count != oldSections.count) {
        
        // Find deleted sections
        NSMutableArray *deletedSections = [oldSections mutableCopy];
        // Remove the sections in new, to identify any deleted sections
        [deletedSections removeObjectsInArray:newFetchedResultsObject.sections];
        
        for (RBQFetchedResultsSectionInfo *sectionInfo in deletedSections) {
            NSUInteger oldSectionIndex = [oldSections indexOfObjectIdenticalTo:sectionInfo];
            
            if ([self.delegate
                 respondsToSelector:@selector(controller:didChangeSection:atIndex:forChangeType:)])
            {
                dispatch_sync(dispatch_get_main_queue(), ^{
                    [self.delegate controller:self
                             didChangeSection:sectionInfo
                                      atIndex:oldSectionIndex
                                forChangeType:NSFetchedResultsChangeDelete];
                });
            }
        }
        
        // Find inserted sections
        NSMutableArray *insertedSections = [newFetchedResultsObject.sections mutableCopy];
        // Remove the sections in new, to identify any deleted sections
        [insertedSections removeObjectsInArray:oldSections];
        
        for (RBQFetchedResultsSectionInfo *sectionInfo in insertedSections) {
            NSUInteger newSectionIndex = [newFetchedResultsObject.sections
                                          indexOfObjectIdenticalTo:sectionInfo];
            
            if ([self.delegate
                 respondsToSelector:@selector(controller:didChangeSection:atIndex:forChangeType:)])
            {
                dispatch_sync(dispatch_get_main_queue(), ^{
                    [self.delegate controller:self
                             didChangeSection:sectionInfo
                                      atIndex:newSectionIndex
                                forChangeType:NSFetchedResultsChangeInsert];
                });
            }
        }
    }
}

- (void)identifyChangesFromLatestResults:(RBQFetchedResultsObject *)newFetchedResultsObject
                 oldFetchedResultsObject:(RBQFetchedResultsObject *)oldFetchedResultsObject
                  withChangedSafeObjects:(NSArray *)changedSafeObjects
{
    for (RBQSafeRealmObject *object in changedSafeObjects) {
        
        NSIndexPath *newIndexPath = newFetchedResultsObject.objectKeyMap[object];
        NSIndexPath *oldIndexPath = oldFetchedResultsObject.objectKeyMap[object];
        
        // Item was removed from change
        if (!newIndexPath && oldIndexPath) {
            
            if ([self.delegate respondsToSelector:
                 @selector(controller:didChangeObject:atIndexPath:forChangeType:newIndexPath:)])
            {
                dispatch_sync(dispatch_get_main_queue(), ^{
                    [self.delegate controller:self
                              didChangeObject:object
                                  atIndexPath:oldIndexPath
                                forChangeType:NSFetchedResultsChangeDelete
                                 newIndexPath:nil];
                });
            }
        }
        // Item was inserted from change
        else if (newIndexPath && !oldIndexPath) {
            
            if ([self.delegate respondsToSelector:
                 @selector(controller:didChangeObject:atIndexPath:forChangeType:newIndexPath:)])
            {
                dispatch_sync(dispatch_get_main_queue(), ^{
                    [self.delegate controller:self
                              didChangeObject:object
                                  atIndexPath:nil
                                forChangeType:NSFetchedResultsChangeInsert
                                 newIndexPath:newIndexPath];
                });
            }
        }
        // Item was moved from change
        else if ([newIndexPath compare:oldIndexPath] != NSOrderedSame) {
            
            if ([self.delegate respondsToSelector:
                 @selector(controller:didChangeObject:atIndexPath:forChangeType:newIndexPath:)])
            {
                dispatch_sync(dispatch_get_main_queue(), ^{
                    [self.delegate controller:self
                              didChangeObject:object
                                  atIndexPath:oldIndexPath
                                forChangeType:NSFetchedResultsChangeMove
                                 newIndexPath:newIndexPath];
                });
            }
        }
        // Item updated -- may have to redraw
        else if ([newIndexPath compare:oldIndexPath] == NSOrderedSame) {
            
            if ([self.delegate respondsToSelector:
                 @selector(controller:didChangeObject:atIndexPath:forChangeType:newIndexPath:)])
            {
                dispatch_sync(dispatch_get_main_queue(), ^{
                    [self.delegate controller:self
                              didChangeObject:object
                                  atIndexPath:newIndexPath
                                forChangeType:NSFetchedResultsChangeUpdate
                                 newIndexPath:nil];
                });
            }
        }
        // Missing else: item wasn't there before or after, but was edited -- don't care
    }
}

- (void)identifyChangesFromLatestResults:(RBQFetchedResultsObject *)newFetchedResultsObject
                    withAddedSafeObjects:(NSArray *)addedSafeObjects
{
    for (RBQSafeRealmObject *object in addedSafeObjects) {
        NSIndexPath *newIndexPath = newFetchedResultsObject.objectKeyMap[object];
        
        // Added item was inserted
        if (newIndexPath) {
            
            if ([self.delegate respondsToSelector:
                 @selector(controller:didChangeObject:atIndexPath:forChangeType:newIndexPath:)])
            {
                dispatch_sync(dispatch_get_main_queue(), ^{
                    [self.delegate controller:self
                              didChangeObject:object
                                  atIndexPath:nil
                                forChangeType:NSFetchedResultsChangeInsert
                                 newIndexPath:newIndexPath];
                });
            }
        }
    }
}

- (void)identifyChangesFromLatestResults:(RBQFetchedResultsObject *)newFetchedResultsObject
                 oldFetchedResultsObject:(RBQFetchedResultsObject *)oldFetchedResultsObject
                  withDeletedSafeObjects:(NSArray *)deletedSafeObjects
{
    for (RBQSafeRealmObject *object in deletedSafeObjects) {
        NSIndexPath *oldIndexPath = oldFetchedResultsObject.objectKeyMap[object];
        NSIndexPath *newIndexPath = newFetchedResultsObject.objectKeyMap[object];
        
        // Item was deleted
        if (oldIndexPath && !newIndexPath) {
            
            if ([self.delegate respondsToSelector:
                 @selector(controller:didChangeObject:atIndexPath:forChangeType:newIndexPath:)])
            {
                dispatch_sync(dispatch_get_main_queue(), ^{
                    [self.delegate controller:self
                              didChangeObject:object
                                  atIndexPath:oldIndexPath
                                forChangeType:NSFetchedResultsChangeDelete
                                 newIndexPath:nil];
                });
            }
        }
    }
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
    
    NSLog(@"Fetched %u objects", fetchResults.count);
    
    return fetchResults;
}

- (RBQFetchedResultsObject *)fetchedResultsObjectWithFetchResults:(RLMResults *)fetchResults
                                               sectionNameKeyPath:(NSString *)sectionNameKeyPath
{
    // Create our maps
    NSMutableArray *fetchedObjects = @[].mutableCopy;
    NSMutableArray *sections = @[].mutableCopy;
    NSMutableArray *sectionTitles = @[].mutableCopy;
    NSMutableDictionary *indexPathKeyMap = @{}.mutableCopy;
    NSMutableDictionary *objectKeyMap = @{}.mutableCopy;
    
    NSString *currentSectionTitle = nil;
    NSUInteger sectionIndex = 0;
    NSUInteger rowIndex = 0;
    NSUInteger count = 0;
    
    NSMutableArray *sectionObjects = @[].mutableCopy;
    
    /**
     This loop processes the objects in one pass.
     
     The sectionTitles array keeps track of the sections and the logic is
     that as we advance to a new section, we save the previous one. Then on
     the final object, we save the last section.
     */
    for (RLMObject *object in fetchResults) {
        // Keep track of the count
        count ++;
        
        // Create the safe object
        RBQSafeRealmObject *safeObject = [RBQSafeRealmObject safeObjectFromObject:object];
        
        if (sectionNameKeyPath) {
            
            NSString *sectionTitle = [object valueForKey:sectionNameKeyPath];
            
            // New Section Found --> Process It
            if (![sectionTitles containsObject:sectionTitle]) {
                
                // Keep track of the section titles to process sections once
                [sectionTitles addObject:sectionTitle];
                
                // Advance the section index if we already found first section
                if (currentSectionTitle) {
                    sectionIndex ++;
                }
                
                // Reset the row index everytime we move to a new section
                rowIndex = 0;
                
                // If we already gathered up the section objects, then save them
                if (sectionObjects.count > 0) {
                    
                    RBQFetchedResultsSectionInfo *sectionInfo =
                        [[RBQFetchedResultsSectionInfo alloc] initWithName:currentSectionTitle
                                                                   objects:sectionObjects.copy];
                    [sections addObject:sectionInfo];
                }
                
                currentSectionTitle = sectionTitle;
                
                // Reset the section object array
                sectionObjects = @[].mutableCopy;
            }
        }
        
        // Add the object to the section object array
        [sectionObjects addObject:safeObject];
        
        // Save the final section
        if (count == fetchResults.count && sectionNameKeyPath) {

            RBQFetchedResultsSectionInfo *sectionInfo =
                [[RBQFetchedResultsSectionInfo alloc] initWithName:currentSectionTitle
                                                           objects:sectionObjects.copy];
            [sections addObject:sectionInfo];
        }
        
        // Create the indexPath for the object
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:rowIndex inSection:sectionIndex];
        
        // Save the safe object
        [fetchedObjects addObject:safeObject];
        
        // Set the maps
        indexPathKeyMap[indexPath] = safeObject;
        objectKeyMap[safeObject] = indexPath;
        
        // Advance the row index for each object
        rowIndex++;
    }
    
    // If we aren't using sections, create a mock one
    if (sections.count == 0) {
        RBQFetchedResultsSectionInfo *sectionInfo =
            [[RBQFetchedResultsSectionInfo alloc] initWithName:@"SingleSection"
                                                       objects:sectionObjects.copy];
        [sections addObject:sectionInfo];
    }
    
    RBQFetchedResultsObject *fetchedResults = [[RBQFetchedResultsObject alloc] init];
    fetchedResults.sections = sections.copy;
    fetchedResults.fetchedObjects = fetchedObjects.copy;
    fetchedResults.indexPathKeyMap = indexPathKeyMap.copy;
    fetchedResults.objectKeyMap = objectKeyMap.copy;
    
    return fetchedResults;
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
