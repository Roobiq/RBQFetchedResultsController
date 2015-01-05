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
@synthesize numberOfObjects = _numberOfObjects,
objects = _objects,
name = _name;

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
        return [_name hash] ^ 1;
    }
    else {
        return [super hash];
    }
}

@end

#pragma mark - RBQFetchedResultsObject

// Object representing all of the various structures needed
@interface RBQFetchedResultsObject : NSObject

@property (strong, nonatomic) NSArray *fetchedObjects;
@property (strong, nonatomic) NSArray *sections;
@property (strong, nonatomic) NSDictionary *indexPathKeyMap;
@property (strong, nonatomic) NSDictionary *objectKeyMap;

@end

@implementation RBQFetchedResultsObject

@end

@interface RBQFetchedResultsController ()

@property (strong, nonatomic) RBQNotificationToken *notificationToken;

@property (strong, nonatomic) RBQFetchedResultsObject *fetchedResultsObject;

@end

#pragma mark - RBQFetchedResultsController

@implementation RBQFetchedResultsController

@synthesize fetchedObjects = _fetchedObjects,
fetchRequest = _fetchRequest,
sectionNameKeyPath = _sectionNameKeyPath,
sections = _sections;

#pragma mark - Public

- (id)initWithFetchRequest:(RBQFetchRequest *)fetchRequest
        sectionNameKeyPath:(NSString *)sectionNameKeyPath
{
    self = [super init];
    
    if (self) {
        _fetchRequest = fetchRequest;
        _sectionNameKeyPath = sectionNameKeyPath;
        
        [self registerChangeNotification];
    }
    
    return self;
}

- (BOOL)performFetch
{
    if (self.fetchRequest) {
        
        RLMResults *fetchResults = [self fetchResultsForFetchRequest:self.fetchRequest];
        
        RBQFetchedResultsObject *fetchedResultsObject = [self fetchedResultsObjectWithFetchResults:fetchResults
                                                                                sectionNameKeyPath:self.sectionNameKeyPath];
        
        [self updatePropertiesWithFetchedResults:fetchedResultsObject];
        
        return YES;
    }
    
    @throw [NSException exceptionWithName:@"RBQException"
                                   reason:@"Unable to perform fetch; fetchRequest must be set first."
                                 userInfo:nil];
    
    return NO;
}

- (void)updatePropertiesWithFetchedResults:(RBQFetchedResultsObject *)fetchedResultsObject
{
    _sections = fetchedResultsObject.sections;
    _fetchedObjects = fetchedResultsObject.fetchedObjects;
    _fetchedResultsObject = fetchedResultsObject;
}

- (RBQSafeRealmObject *)safeObjectAtIndexPath:(NSIndexPath *)indexPath
{
    return [_fetchedResultsObject.indexPathKeyMap objectForKey:[self keyForIndexPath:indexPath]];
}

- (id)objectAtIndexPath:(NSIndexPath *)indexPath
{
    RBQSafeRealmObject *safeObject = [_fetchedResultsObject.indexPathKeyMap objectForKey:[self keyForIndexPath:indexPath]];
    
    return [safeObject RLMObject];
}

- (NSIndexPath *)indexPathForSafeObject:(RBQSafeRealmObject *)safeObject
{
    return [_fetchedResultsObject.objectKeyMap objectForKey:safeObject];
}

- (NSIndexPath *)indexPathForObject:(RLMObject *)object
{
    RBQSafeRealmObject *safeObject = [RBQSafeRealmObject safeObjectFromObject:object];
    
    return [_fetchedResultsObject.objectKeyMap objectForKey:safeObject];
}

#pragma mark - Private

- (void)registerChangeNotification
{
    // Start Notifications
    self.notificationToken =
    [[RBQRealmNotificationManager defaultManager] addNotificationBlock:^(NSArray *addedSafeObjects,
                                                                         NSArray *deletedSafeObjects,
                                                                         NSArray *changedSafeObjects,
                                                                         RLMRealm *realm) {
        // Get the new list of safe fetch objects
        RLMResults *fetchResults = [self fetchResultsForFetchRequest:self.fetchRequest];
        
        RBQFetchedResultsObject *fetchedResultsObject = [self fetchedResultsObjectWithFetchResults:fetchResults
                                                                                sectionNameKeyPath:self.sectionNameKeyPath];

        dispatch_async(dispatch_get_main_queue(), ^(){
            if ([self.delegate respondsToSelector:@selector(controllerWillChangeContent:)]) {
                [self.delegate controllerWillChangeContent:self];
            }
            
            // Identify section changes
            [self identifySectionChangesFromLatestResults:fetchedResultsObject
                                              oldSections:self.sections];
            
            // Identify changes and moves first
            [self identifyChangesFromLatestResults:fetchedResultsObject
                            withChangedSafeObjects:changedSafeObjects];
            
            [self identifyChangesFromLatestResults:fetchedResultsObject
                              withAddedSafeObjects:addedSafeObjects];
            
            [self identifyChangesFromLatestResults:fetchedResultsObject
                            withDeletedSafeObjects:deletedSafeObjects];
            
            // Now update our properties
            [self updatePropertiesWithFetchedResults:fetchedResultsObject];
            
            if ([self.delegate respondsToSelector:@selector(controllerDidChangeContent:)]) {
                [self.delegate controllerDidChangeContent:self];
            }
        });
    }];
}

- (void)identifySectionChangesFromLatestResults:(RBQFetchedResultsObject *)newFetchedResultsObject
                                    oldSections:(NSArray *)oldSections
{
    if (newFetchedResultsObject.sections.count != oldSections.count) {
        
        // Find deleted sections
        NSMutableArray *deletedSections = [NSMutableArray arrayWithArray:oldSections];
        // Remove the sections in new, to identify any deleted sections
        [deletedSections removeObjectsInArray:newFetchedResultsObject.sections];
        
        if (deletedSections.count > 0) {
            for (RBQFetchedResultsSectionInfo *sectionInfo in deletedSections) {
                NSUInteger oldSectionIndex = [oldSections indexOfObjectIdenticalTo:sectionInfo];
                
                if ([self.delegate respondsToSelector:@selector(controller:didChangeSection:atIndex:forChangeType:)]) {
                    [self.delegate controller:self
                             didChangeSection:sectionInfo
                                      atIndex:oldSectionIndex
                                forChangeType:NSFetchedResultsChangeDelete];
                }
            }
        }
        
        // Find inserted sections
        NSMutableArray *insertedSections = [NSMutableArray arrayWithArray:newFetchedResultsObject.sections];
        // Remove the sections in new, to identify any deleted sections
        [insertedSections removeObjectsInArray:oldSections];
        
        if (insertedSections.count > 0) {
            for (RBQFetchedResultsSectionInfo *sectionInfo in insertedSections) {
                NSUInteger newSectionIndex = [newFetchedResultsObject.sections indexOfObjectIdenticalTo:sectionInfo];
                
                if ([self.delegate respondsToSelector:@selector(controller:didChangeSection:atIndex:forChangeType:)]) {
                    [self.delegate controller:self
                             didChangeSection:sectionInfo
                                      atIndex:newSectionIndex
                                forChangeType:NSFetchedResultsChangeInsert];
                }
            }
        }
    }
}

- (void)identifyChangesFromLatestResults:(RBQFetchedResultsObject *)newFetchedResultsObject
                  withChangedSafeObjects:(NSArray *)changedSafeObjects
{
    for (RBQSafeRealmObject *object in changedSafeObjects) {
        
        NSIndexPath *newIndexPath = [newFetchedResultsObject.objectKeyMap objectForKey:object];
        
        NSIndexPath *oldIndexPath = [_fetchedResultsObject.objectKeyMap objectForKey:object];
        
        // Item was removed from change
        if (!newIndexPath &&
            oldIndexPath) {
            
            if ([self.delegate
                 respondsToSelector:@selector(controller:didChangeObject:atIndexPath:forChangeType:newIndexPath:)]) {
                
                [self.delegate controller:self
                          didChangeObject:object
                              atIndexPath:oldIndexPath
                            forChangeType:NSFetchedResultsChangeDelete
                             newIndexPath:nil];
            }
        }
        // Item was inserted from change
        else if (newIndexPath &&
                 !oldIndexPath) {
            
            if ([self.delegate
                 respondsToSelector:@selector(controller:didChangeObject:atIndexPath:forChangeType:newIndexPath:)]) {
                
                [self.delegate controller:self
                          didChangeObject:object
                              atIndexPath:nil
                            forChangeType:NSFetchedResultsChangeInsert
                             newIndexPath:newIndexPath];
            }
        }
        // Item was moved from change
        else if ([newIndexPath compare:oldIndexPath]) {
            if ([self.delegate
                 respondsToSelector:@selector(controller:didChangeObject:atIndexPath:forChangeType:newIndexPath:)]) {
                
                [self.delegate controller:self
                          didChangeObject:object
                              atIndexPath:oldIndexPath
                            forChangeType:NSFetchedResultsChangeMove
                             newIndexPath:newIndexPath];
            }
        }
        else {
            if ([self.delegate
                 respondsToSelector:@selector(controller:didChangeObject:atIndexPath:forChangeType:newIndexPath:)]) {
                
                [self.delegate controller:self
                          didChangeObject:object
                              atIndexPath:newIndexPath
                            forChangeType:NSFetchedResultsChangeUpdate
                             newIndexPath:nil];
            }
        }
    }
}

- (void)identifyChangesFromLatestResults:(RBQFetchedResultsObject *)newFetchedResultsObject
                    withAddedSafeObjects:(NSArray *)addedSafeObjects
{
    for (RBQSafeRealmObject *object in addedSafeObjects) {
        NSIndexPath *newIndexPath = [newFetchedResultsObject.objectKeyMap objectForKey:object];
        
        // Added item was inserted
        if (newIndexPath) {
            
            if ([self.delegate
                 respondsToSelector:@selector(controller:didChangeObject:atIndexPath:forChangeType:newIndexPath:)]) {
                
                [self.delegate controller:self
                          didChangeObject:object
                              atIndexPath:nil
                            forChangeType:NSFetchedResultsChangeInsert
                             newIndexPath:newIndexPath];
            }
        }
    }
}

- (void)identifyChangesFromLatestResults:(RBQFetchedResultsObject *)newFetchedResultsObject
                  withDeletedSafeObjects:(NSArray *)deletedSafeObjects
{
    for (RBQSafeRealmObject *object in deletedSafeObjects) {
        NSIndexPath *oldIndexPath = [_fetchedResultsObject.objectKeyMap objectForKey:object];
        
        // Item was deleted
        if (oldIndexPath) {
            
            if ([self.delegate
                 respondsToSelector:@selector(controller:didChangeObject:atIndexPath:forChangeType:newIndexPath:)]) {
                
                [self.delegate controller:self
                          didChangeObject:object
                              atIndexPath:oldIndexPath
                            forChangeType:NSFetchedResultsChangeDelete
                             newIndexPath:nil];
            }
        }
    }
}

- (RLMResults *)fetchResultsForFetchRequest:(RBQFetchRequest *)fetchRequest
{
    RLMResults *fetchResults = [NSClassFromString(fetchRequest.entityName) allObjects];
    
    // If we have a predicate use it
    if (fetchRequest.predicate) {
        fetchResults = [fetchResults objectsWithPredicate:fetchRequest.predicate];
    }
    
    // If we have sort descriptors then use them
    if (fetchRequest.sortDescriptors.count > 0) {
        fetchResults = [fetchResults sortedResultsUsingDescriptors:fetchRequest.sortDescriptors];
    }
    
    return fetchResults;
}

- (RBQFetchedResultsObject *)fetchedResultsObjectWithFetchResults:(RLMResults *)fetchResults
                                               sectionNameKeyPath:(NSString *)sectionNameKeyPath
{
    // Create our maps
    NSMutableArray *fetchedObjects = @[].mutableCopy;
    NSMutableArray *sections = @[].mutableCopy;
    NSMutableDictionary *indexPathKeyMap = @{}.mutableCopy;
    NSMutableDictionary *objectKeyMap = @{}.mutableCopy;
    
    NSString *currentSectionTitle = nil;
    NSUInteger sectionIndex = 0;
    NSUInteger rowIndex = 0;
    
    for (RLMObject *object in fetchResults) {
        
        if (sectionNameKeyPath) {
            NSString *sectionTitle = [object valueForKey:sectionNameKeyPath];
            
            if (!currentSectionTitle ||
                ![sectionTitle isEqualToString:currentSectionTitle]) {
                
                // Advance the section index if we already found first section
                if (currentSectionTitle) {
                    sectionIndex ++;
                }
                
                // Reset the row index everytime we move to a new section
                rowIndex = 0;
                
                currentSectionTitle = sectionTitle;
                
                // Get the slice of results for the section
                NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %@",
                                          sectionNameKeyPath,
                                          currentSectionTitle];
                
                RLMResults *sectionResults = [fetchResults objectsWithPredicate:predicate];
                
                NSMutableArray *sectionObjects = @[].mutableCopy;
                
                for (RLMObject *sectionObject in sectionResults) {
                    RBQSafeRealmObject *safeSectionObject = [RBQSafeRealmObject safeObjectFromObject:sectionObject];
                    
                    [sectionObjects addObject:safeSectionObject];
                }
                
                RBQFetchedResultsSectionInfo *sectionInfo =
                [[RBQFetchedResultsSectionInfo alloc] initWithName:currentSectionTitle
                                                           objects:sectionObjects.copy];
                
                [sections addObject:sectionInfo];
            }
        }
        
        // Create the indexPath for the object
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:rowIndex inSection:sectionIndex];
        
        // Create the safe object
        RBQSafeRealmObject *safeObject = [RBQSafeRealmObject safeObjectFromObject:object];
        
        // Save the safe object
        [fetchedObjects addObject:safeObject];
        
        // Set the maps
        [indexPathKeyMap setObject:safeObject forKey:indexPath];
        [objectKeyMap setObject:indexPath forKey:safeObject];
        
        // Advance the row index for each object
        rowIndex ++;
    }
    
    // If we aren't using sections, create a mock one
    if (sections.count == 0) {
        RBQFetchedResultsSectionInfo *sectionInfo =
        [[RBQFetchedResultsSectionInfo alloc] initWithName:@"SingleSection"
                                                   objects:fetchedObjects.copy];
        
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

/*  Apparently iOS 7+ NSIndexPath's can sometimes be NSMutableIndexPaths:
    http://stackoverflow.com/questions/18919459/ios-7-beginupdates-endupdates-inconsistent/18920573#18920573
*/
- (NSIndexPath *)keyForIndexPath:(NSIndexPath *)indexPath
{
    if ([indexPath class] == [NSIndexPath class]) {
        return indexPath;
    }
    return [NSIndexPath indexPathForRow:indexPath.row inSection:indexPath.section];
}

@end
