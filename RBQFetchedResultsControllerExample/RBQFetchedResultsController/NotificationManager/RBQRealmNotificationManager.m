//
//  RBQRealmNotificationManager.m
//  RBQFetchedResultsControllerTest
//
//  Created by Lauren Smith on 1/4/15.
//  Copyright (c) 2015 Roobiq. All rights reserved.
//

#import "RBQRealmNotificationManager.h"
#import "RBQSafeRealmObject.h"

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

#pragma mark - RBQRealmNotificationManager

@interface RBQRealmNotificationManager ()

@property (strong, nonatomic) NSString *realmPath;
@property (strong, nonatomic) RLMRealm *inMemoryRealm;

@property (strong, nonatomic) NSMutableArray *addedSafeObjects;
@property (strong, nonatomic) NSMutableArray *deletedSafeObjects;
@property (strong, nonatomic) NSMutableArray *changedSafeObjects;

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
                                                     valueOptions:NSPointerFunctionsWeakMemory];
            
            return nil;
        }
        
        return [pathToManagerMap objectForKey:path];
    }
}

@implementation RBQRealmNotificationManager

#pragma mark - Class

+ (instancetype)defaultManager
{
    static RBQRealmNotificationManager *defaultManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        defaultManager = [RBQRealmNotificationManager managerForRealm:[RLMRealm defaultRealm]];
    });
    return defaultManager;
}

+ (instancetype)managerForRealm:(RLMRealm *)realm
{
    static RBQRealmNotificationManager *defaultManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        defaultManager = cachedRealmNotificationManager(realm.path);
        
        if (!defaultManager) {
            defaultManager = [[self alloc] init];
            
            defaultManager.realmPath = realm.path;
            
            [defaultManager registerChangeNotification];
            
            // Add the manager to the cache
            [pathToManagerMap setObject:defaultManager forKey:realm.path];
        }
    });
    return defaultManager;
}

+ (instancetype)managerForInMemoryRealm:(RLMRealm *)inMemoryRealm
{
    static RBQRealmNotificationManager *defaultManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        defaultManager = cachedRealmNotificationManager(inMemoryRealm.path);
        
        if (!defaultManager) {
            defaultManager = [[self alloc] init];
            
            defaultManager.inMemoryRealm = inMemoryRealm;
            
            [defaultManager registerChangeNotification];
            
            // Add the manager to the cache
            [pathToManagerMap setObject:defaultManager forKey:inMemoryRealm.path];
        }
    });
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
    [_notificationHandlers setObject:token forKey:token];
    return token;
}

- (void)removeNotification:(RBQNotificationToken *)token
{
    if (token) {
        [_notificationHandlers removeObjectForKey:token];
        token.realmPath = nil;
        token.inMemoryRealm = nil;
        token.block = nil;
    }
}

#pragma mark - Public Change Methods

- (void)didAddObject:(RLMObject *)addedObject
{
    // Save a safe object to use across threads
    RBQSafeRealmObject *safeObject = [RBQSafeRealmObject safeObjectFromObject:addedObject];
    
    if (![self.addedSafeObjects containsObject:safeObject]) {
        [self.addedSafeObjects addObject:safeObject];
    }
}

- (void)willDeleteObject:(RLMObject *)deletedObject
{
    // Save a safe object to use across threads
    RBQSafeRealmObject *safeObject = [RBQSafeRealmObject safeObjectFromObject:deletedObject];
    
    if (![self.deletedSafeObjects containsObject:safeObject]) {
        [self.deletedSafeObjects addObject:safeObject];
    }
}

- (void)didChangeObject:(RLMObject *)changedObject
{
    // Save a safe object to use across threads
    RBQSafeRealmObject *safeObject = [RBQSafeRealmObject safeObjectFromObject:changedObject];
    
    if (![self.changedSafeObjects containsObject:safeObject]) {
        [self.changedSafeObjects addObject:safeObject];
    }
}

- (void)didAddObjects:(NSArray *)addedObjects
    willDeleteObjects:(NSArray *)deletedObjects
     didChangeObjects:(NSArray *)changedObjects
{
    if (addedObjects) {
        
        for (RLMObject *addedObject in addedObjects) {
            
            if (addedObject &&
                addedObject != (id)[NSNull null]) {
                
                // Save a safe object to use across threads
                RBQSafeRealmObject *safeObject = [RBQSafeRealmObject safeObjectFromObject:addedObject];
                
                if (![self.addedSafeObjects containsObject:safeObject]) {
                    [self.addedSafeObjects addObject:safeObject];
                }
            }
        }
    }
    
    if (deletedObjects) {
        
        for (RLMObject *deletedObject in deletedObjects) {
            
            if (deletedObject &&
                deletedObject != (id)[NSNull null]) {
                
                // Save a safe object to use across threads
                RBQSafeRealmObject *safeObject = [RBQSafeRealmObject safeObjectFromObject:deletedObject];
                
                if (![self.deletedSafeObjects containsObject:safeObject]) {
                    [self.deletedSafeObjects addObject:safeObject];
                }
            }
        }
    }
    
    if (changedObjects) {
        
        for (RLMObject *changedObject in changedObjects) {
            
            if (changedObject &&
                changedObject != (id)[NSNull null]) {
                
                // Save a safe object to use across threads
                RBQSafeRealmObject *safeObject = [RBQSafeRealmObject safeObjectFromObject:changedObject];
                
                if (![self.changedSafeObjects containsObject:safeObject]) {
                    [self.changedSafeObjects addObject:safeObject];
                }
            }
        }
    }
}

#pragma mark - Getters

- (NSMutableArray *)addedSafeObjects
{
    if (!_addedSafeObjects) {
        _addedSafeObjects = @[].mutableCopy;
    }
    
    return _addedSafeObjects;
}

- (NSMutableArray *)deletedSafeObjects
{
    if (!_deletedSafeObjects) {
        _deletedSafeObjects = @[].mutableCopy;
    }
    
    return _deletedSafeObjects;
}

- (NSMutableArray *)changedSafeObjects
{
    if (!_changedSafeObjects) {
        _changedSafeObjects = @[].mutableCopy;
    }
    
    return _changedSafeObjects;
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
        if (token.block &&
            (self.addedSafeObjects.count > 0 ||
            self.deletedSafeObjects.count > 0 ||
            self.changedSafeObjects.count > 0)) {
                
            token.block(self.addedSafeObjects.copy,
                        self.deletedSafeObjects.copy,
                        self.changedSafeObjects.copy,
                        realm);
        }
    }
    
    self.addedSafeObjects = nil;
    self.deletedSafeObjects = nil;
    self.changedSafeObjects = nil;
}

#pragma mark - Grab RLMObjects For Current Thread

- (NSArray *)addedObjects
{
    NSMutableArray *addedObjects = @[].mutableCopy;
    
    for (RBQSafeRealmObject *safeObject in self.addedSafeObjects) {
        RLMObject *object = [RBQSafeRealmObject objectInRealm:[self realmForManager]
                                               fromSafeObject:safeObject];
        
        if (object) {
            [addedObjects addObject:object];
        }
    }
    
    return addedObjects.copy;
}

- (NSArray *)deletedObjects
{
    NSMutableArray *deletedObjects = @[].mutableCopy;
    
    for (RBQSafeRealmObject *safeObject in self.deletedSafeObjects) {
        RLMObject *object = [RBQSafeRealmObject objectInRealm:[self realmForManager]
                                               fromSafeObject:safeObject];
        
        if (object) {
            [deletedObjects addObject:object];
        }
    }
    
    return deletedObjects.copy;
}

- (NSArray *)changedObjects
{
    NSMutableArray *changedObjects = @[].mutableCopy;
    
    for (RBQSafeRealmObject *safeObject in self.changedSafeObjects) {
        RLMObject *object = [RBQSafeRealmObject objectInRealm:[self realmForManager]
                                               fromSafeObject:safeObject];
        
        if (object) {
            [changedObjects addObject:object];
        }
    }
    
    return changedObjects.copy;
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

@end
