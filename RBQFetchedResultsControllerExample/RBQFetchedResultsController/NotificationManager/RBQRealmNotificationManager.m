//
//  RBQRealmNotificationManager.m
//  RBQFetchedResultsControllerTest
//
//  Created by Lauren Smith on 1/4/15.
//  Copyright (c) 2015 Roobiq. All rights reserved.
//

#import "RBQRealmNotificationManager.h"
#import "RBQSafeRealmObject.h"

#pragma mark - RBQEntityChangesObject

@interface RBQEntityChangesObject ()

@property (strong, nonatomic) NSMutableSet *internalAddedSafeObjects;
@property (strong, nonatomic) NSMutableSet *internalDeletedSafeObjects;
@property (strong, nonatomic) NSMutableSet *internalChangedSafeObjects;

+ (instancetype)createEntityChangeObjectWithClassName:(NSString *)className;

- (void)didAddSafeObject:(RBQSafeRealmObject *)safeObject;
- (void)willDeleteSafeObject:(RBQSafeRealmObject *)safeObject;
- (void)didChangeSafeObject:(RBQSafeRealmObject *)safeObject;

@end

@implementation RBQEntityChangesObject
@synthesize className = _className;

+ (instancetype)createEntityChangeObjectWithClassName:(NSString *)className
{
    RBQEntityChangesObject *changeObject = [[RBQEntityChangesObject alloc] init];
    changeObject->_className = className;
    changeObject.internalAddedSafeObjects = [[NSMutableSet alloc] init];
    changeObject.internalDeletedSafeObjects = [[NSMutableSet alloc] init];
    changeObject.internalChangedSafeObjects = [[NSMutableSet alloc] init];
    
    return changeObject;
}

- (void)didAddSafeObject:(RBQSafeRealmObject *)safeObject
{
    @synchronized(self.internalAddedSafeObjects) {
        if (![self.internalAddedSafeObjects containsObject:safeObject]) {
            [self.internalAddedSafeObjects addObject:safeObject];
        }
    }
}

- (void)willDeleteSafeObject:(RBQSafeRealmObject *)safeObject
{
    @synchronized(self.internalDeletedSafeObjects) {
        if (![self.internalDeletedSafeObjects containsObject:safeObject]) {
            [self.internalDeletedSafeObjects addObject:safeObject];
        }
    }
}

- (void)didChangeSafeObject:(RBQSafeRealmObject *)safeObject
{
    @synchronized(self.internalChangedSafeObjects) {
        if (![self.internalChangedSafeObjects containsObject:safeObject]) {
            [self.internalChangedSafeObjects addObject:safeObject];
        }
    }
}

#pragma mark - Getters

- (NSSet *)addedSafeObjects
{
    return self.internalAddedSafeObjects.copy;
}

- (NSSet *)deletedSafeObjects
{
    return self.internalDeletedSafeObjects.copy;
}

- (NSSet *)changedSafeObjects
{
    return self.internalChangedSafeObjects.copy;
}

@end

#pragma mark - RBQNotificationToken

@interface RBQNotificationToken ()

@property (nonatomic, strong) NSString *realmPath;
@property (nonatomic, strong) RLMRealm *inMemoryRealm;
@property (nonatomic, copy) RBQNotificationBlock block;

@end

@implementation RBQNotificationToken

- (void)dealloc
{
    if (_realmPath || _block) {
        NSLog(@"RBQNotificationToken released without unregistering a notification. You must hold \
              on to the RBQNotificationToken returned from addNotificationBlock and call \
              removeNotification: when you no longer wish to recieve RBQRealm notifications.");
    }
}

@end

#pragma mark - Constants

NSString * const kRBQAddedSafeObjectsKey = @"RBQAddedSafeObjectsKey";
NSString * const kRBQDeletedSafeObjectsKey = @"RBQDeletedSafeObjectsKey";
NSString * const kRBQChangedSafeObjectsKey = @"RBQChangedSafeObjectsKey ";

#pragma mark - RBQRealmNotificationManager

@interface RBQRealmNotificationManager ()

@property (strong, nonatomic) NSString *realmPath;
@property (strong, nonatomic) RLMRealm *inMemoryRealm;

@property (strong, nonatomic) NSMutableDictionary *internalEntityChanges;

@property (strong, nonatomic) RLMNotificationToken *token;

@property (strong, nonatomic) NSMapTable *notificationHandlers;

@end

#pragma mark - Global

// Global map to return the same notification manager for each Realm
NSMapTable *pathToManagerMap;

RBQRealmNotificationManager *cachedRealmNotificationManager(NSString *path) {
    @synchronized(pathToManagerMap) {
        
        // Create the map if not initialized
        if (!pathToManagerMap) {
            pathToManagerMap = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsStrongMemory
                                                     valueOptions:NSPointerFunctionsStrongMemory];
            
            return nil;
        }
        
        return [pathToManagerMap objectForKey:path];
    }
}

@implementation RBQRealmNotificationManager

#pragma mark - Class

+ (instancetype)defaultManager
{
    return [RBQRealmNotificationManager managerForRealm:[RLMRealm defaultRealm]];
}

+ (instancetype)managerForRealm:(RLMRealm *)realm
{
    RBQRealmNotificationManager *defaultManager = cachedRealmNotificationManager(realm.path);
    
    if (!defaultManager) {
        defaultManager = [[self alloc] init];
        
        defaultManager.realmPath = realm.path;
        
        [defaultManager registerChangeNotification];
        
        // Add the manager to the cache
        @synchronized(pathToManagerMap) {
            [pathToManagerMap setObject:defaultManager forKey:realm.path];
        }
    }
    return defaultManager;
}

+ (instancetype)managerForInMemoryRealm:(RLMRealm *)inMemoryRealm
{
    RBQRealmNotificationManager *defaultManager = cachedRealmNotificationManager(inMemoryRealm.path);
    
    if (!defaultManager) {
        defaultManager = [[self alloc] init];
        
        defaultManager.inMemoryRealm = inMemoryRealm;
        
        [defaultManager registerChangeNotification];
        
        // Add the manager to the cache
        @synchronized(pathToManagerMap) {
            [pathToManagerMap setObject:defaultManager forKey:inMemoryRealm.path];
        }
    }
    return defaultManager;
}

#pragma mark - Instance

- (id)init
{
    self = [super init];
    
    if (self) {
        _notificationHandlers = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsWeakMemory
                                                      valueOptions:NSPointerFunctionsWeakMemory];
    }
    
    return self;
}

#pragma mark - Public Notification Methods

- (RBQNotificationToken *)addNotificationBlock:(RBQNotificationBlock)block
{
    if (!block) {
        @throw [NSException exceptionWithName:@"RBQException"
                                       reason:@"The notification block should not be nil"
                                     userInfo:nil];
    }
    
    RBQNotificationToken *token = [[RBQNotificationToken alloc] init];
    
    if (self.inMemoryRealm) {
        token.inMemoryRealm = self.inMemoryRealm;
    }
    else {
        token.realmPath = self.realmPath;
    }
    
    token.block = block;
    @synchronized(_notificationHandlers) {
        [_notificationHandlers setObject:token forKey:token];
    }
    return token;
}

- (void)removeNotification:(RBQNotificationToken *)token
{
    if (token) {
        @synchronized(_notificationHandlers) {
            [_notificationHandlers removeObjectForKey:token];
        }
        token.realmPath = nil;
        token.inMemoryRealm = nil;
        token.block = nil;
    }
}

#pragma mark - Public Change Methods

- (void)didAddObject:(RLMObject *)addedObject
{
    if (addedObject &&
        !addedObject.invalidated) {
        
        // Save a safe object to use across threads
        RBQSafeRealmObject *safeObject = [RBQSafeRealmObject safeObjectFromObject:addedObject];
        
        RBQEntityChangesObject *entityChangesObject = [self createOrRetrieveEntityChangesForClassName:safeObject.className];
        
        [entityChangesObject didAddSafeObject:safeObject];
    }
}

- (void)didAddObjects:(id<NSFastEnumeration>)addedObjects
{
    if (addedObjects) {
        
        for (RLMObject *addedObject in addedObjects) {
            
            if (addedObject &&
                !addedObject.invalidated) {
                
                // Save a safe object to use across threads
                RBQSafeRealmObject *safeObject = [RBQSafeRealmObject safeObjectFromObject:addedObject];
                
                RBQEntityChangesObject *entityChangesObject = [self createOrRetrieveEntityChangesForClassName:safeObject.className];
                
                [entityChangesObject didAddSafeObject:safeObject];
            }
        }
    }
}

- (void)willDeleteObject:(RLMObject *)deletedObject
{
    if (deletedObject &&
        !deletedObject.invalidated) {
        
        // Save a safe object to use across threads
        RBQSafeRealmObject *safeObject = [RBQSafeRealmObject safeObjectFromObject:deletedObject];
        
        RBQEntityChangesObject *entityChangesObject = [self createOrRetrieveEntityChangesForClassName:safeObject.className];
        
        [entityChangesObject willDeleteSafeObject:safeObject];
    }
}

- (void)willDeleteObjects:(id<NSFastEnumeration>)deletedObjects
{
    if (deletedObjects) {
        
        for (RLMObject *deletedObject in deletedObjects) {
            
            if (deletedObject &&
                !deletedObject.invalidated) {
                
                // Save a safe object to use across threads
                RBQSafeRealmObject *safeObject = [RBQSafeRealmObject safeObjectFromObject:deletedObject];
                
                RBQEntityChangesObject *entityChangesObject = [self createOrRetrieveEntityChangesForClassName:safeObject.className];
                
                [entityChangesObject willDeleteSafeObject:safeObject];
            }
        }
    }
}

- (void)didChangeObject:(RLMObject *)changedObject
{
    if (changedObject &&
        !changedObject.invalidated) {
        
        // Save a safe object to use across threads
        RBQSafeRealmObject *safeObject = [RBQSafeRealmObject safeObjectFromObject:changedObject];
        
        RBQEntityChangesObject *entityChangesObject = [self createOrRetrieveEntityChangesForClassName:safeObject.className];
        
        [entityChangesObject didChangeSafeObject:safeObject];
    }
}

- (void)didChangeObjects:(id<NSFastEnumeration>)changedObjects
{
    if (changedObjects) {
        
        for (RLMObject *changedObject in changedObjects) {
            
            if (changedObject &&
                !changedObject.invalidated) {
                
                // Save a safe object to use across threads
                RBQSafeRealmObject *safeObject = [RBQSafeRealmObject safeObjectFromObject:changedObject];
                
                RBQEntityChangesObject *entityChangesObject = [self createOrRetrieveEntityChangesForClassName:safeObject.className];
                
                [entityChangesObject didChangeSafeObject:safeObject];
            }
        }
    }
}

- (void)didAddObjects:(id<NSFastEnumeration>)addedObjects
    willDeleteObjects:(id<NSFastEnumeration>)deletedObjects
     didChangeObjects:(id<NSFastEnumeration>)changedObjects
{
    if (addedObjects) {
        
        for (RLMObject *addedObject in addedObjects) {
            
            if (addedObject &&
                !addedObject.invalidated) {
                
                // Save a safe object to use across threads
                RBQSafeRealmObject *safeObject = [RBQSafeRealmObject safeObjectFromObject:addedObject];
                
                RBQEntityChangesObject *entityChangesObject = [self createOrRetrieveEntityChangesForClassName:safeObject.className];
                
                [entityChangesObject didAddSafeObject:safeObject];
            }
        }
    }
    
    if (deletedObjects) {
        
        for (RLMObject *deletedObject in deletedObjects) {
            
            if (deletedObject &&
                !deletedObject.invalidated) {
                
                // Save a safe object to use across threads
                RBQSafeRealmObject *safeObject = [RBQSafeRealmObject safeObjectFromObject:deletedObject];
                
                RBQEntityChangesObject *entityChangesObject = [self createOrRetrieveEntityChangesForClassName:safeObject.className];
                
                [entityChangesObject willDeleteSafeObject:safeObject];
            }
        }
    }
    
    if (changedObjects) {
        
        for (RLMObject *changedObject in changedObjects) {
            
            if (changedObject &&
                !changedObject.invalidated) {
                
                // Save a safe object to use across threads
                RBQSafeRealmObject *safeObject = [RBQSafeRealmObject safeObjectFromObject:changedObject];
                
                RBQEntityChangesObject *entityChangesObject = [self createOrRetrieveEntityChangesForClassName:safeObject.className];
                
                [entityChangesObject didChangeSafeObject:safeObject];
            }
        }
    }
}

#pragma mark - Getters

- (NSDictionary *)entityChanges
{
    @synchronized(self.internalEntityChanges) {
        return self.internalEntityChanges.copy;
    }
}

- (NSMutableDictionary *)internalEntityChanges
{
    if (!_internalEntityChanges) {
        _internalEntityChanges = @{}.mutableCopy;
    }
    
    return _internalEntityChanges;
}

#pragma mark - RLMNotification

- (void)registerChangeNotification
{
    self.token = [[self realmForManager]
                  addNotificationBlock:^(NSString *note, RLMRealm *realm) {
                      
                      if ([note isEqualToString:RLMRealmDidChangeNotification]) {
                          [self sendNotificationsWithRealm:realm];
                      }
                  }];
}

#pragma mark - RBQNotification

// Calling this method will broadcast any registered changes
- (void)sendNotificationsWithRealm:(RLMRealm *)realm
{
    // call this realms notification blocks
    for (RBQNotificationToken *token in [_notificationHandlers copy]) {
        if (token.block) {
                
            token.block(self.internalEntityChanges.copy,
                        realm);
        }
    }
    
    self.internalEntityChanges = nil;
}

#pragma mark - Helper

- (RLMRealm *)realmForManager
{
    if (self.inMemoryRealm) {
        return self.inMemoryRealm;
    }
    else if (self.realmPath) {
        return [RLMRealm realmWithPath:self.realmPath];
    }
    
    return nil;
}

- (RBQEntityChangesObject *)createOrRetrieveEntityChangesForClassName:(NSString *)className
{
    RBQEntityChangesObject *entityChangesObject = [self.internalEntityChanges objectForKey:className];
    
    if (!entityChangesObject) {
        entityChangesObject = [RBQEntityChangesObject createEntityChangeObjectWithClassName:className];
        
        @synchronized(self.internalEntityChanges) {
            [self.internalEntityChanges setObject:entityChangesObject forKey:className];
        }
    }
    
    return entityChangesObject;
}

@end
