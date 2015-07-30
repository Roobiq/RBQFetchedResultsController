//
//  RBQRealmNotificationManager.m
//  RBQRealmNotificationManage
//
//  Created by Adam Fish on 1/4/15.
//  Copyright (c) 2015 Roobiq. All rights reserved.
//

#import "RBQRealmNotificationManager.h"
#import "RBQSafeRealmObject.h"

#include <pthread.h>
#import <objc/runtime.h>

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

@property (nonatomic, copy) RBQNotificationBlock block;

@end

@implementation RBQNotificationToken


- (void)dealloc
{
    if (_block) {
        NSLog(@"RBQNotificationToken released without unregistering a notification. You must hold \
              on to the RBQNotificationToken returned from addNotificationBlock and call \
              removeNotification: when you no longer wish to recieve RBQRealm notifications.");
    }
}

@end

#pragma mark - RBQRealmNotificationManager

@interface RBQRealmNotificationManager () {
    NSMapTable *_notificationHandlers;
}

- (void)sendNotificationsWithRealm:(RLMRealm *)realm
                     entityChanges:(NSDictionary *)entityChanges;

@end

@implementation RBQRealmNotificationManager

#pragma mark - Class

+ (instancetype)defaultManager
{
    static RBQRealmNotificationManager *_defaultManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _defaultManager = [[self alloc] init];
    });
    return _defaultManager;
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
        
        token.block = nil;
    }
}

#pragma mark - RBQNotification

// Calling this method will broadcast any registered changes
- (void)sendNotificationsWithRealm:(RLMRealm *)realm
                     entityChanges:(NSDictionary *)entityChanges
{
    // call this realms notification blocks
    for (RBQNotificationToken *token in [_notificationHandlers copy]) {
        if (token.block) {
            
            token.block(entityChanges,
                        realm);
        }
    }
}

@end


#pragma mark - Global

// Global RBQRealmNotificationManager instance cache
static NSMutableDictionary *s_loggersPerPath;

static RBQRealmChangeLogger *cachedRealmChangeLogger(NSString *path) {
    mach_port_t threadID = pthread_mach_thread_np(pthread_self());
    @synchronized(s_loggersPerPath) {
        return [s_loggersPerPath[path] objectForKey:@(threadID)];
    }
}

static void cacheRealmChangeLogger(RBQRealmChangeLogger *logger, NSString *path) {
    mach_port_t threadID = pthread_mach_thread_np(pthread_self());
    @synchronized(s_loggersPerPath) {
        if (!s_loggersPerPath[path]) {
            s_loggersPerPath[path] = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsObjectPersonality
                                                            valueOptions:NSPointerFunctionsWeakMemory];
        }
        [s_loggersPerPath[path] setObject:logger forKey:@(threadID)];
    }
}

static void clearManagerCache() {
    @synchronized(s_loggersPerPath) {
        for (NSMapTable *map in s_loggersPerPath.allValues) {
            [map removeAllObjects];
        }
        s_loggersPerPath = [NSMutableDictionary dictionary];
    }
}

#pragma mark - Constants

static NSString * const kRBQAddedSafeObjectsKey = @"RBQAddedSafeObjectsKey";
static NSString * const kRBQDeletedSafeObjectsKey = @"RBQDeletedSafeObjectsKey";
static NSString * const kRBQChangedSafeObjectsKey = @"RBQChangedSafeObjectsKey";
static char kAssociatedObjectKey;

#pragma mark - RBQRealmChangeLogger

@interface RBQRealmChangeLogger ()

@property (strong, nonatomic) NSMutableDictionary *internalEntityChanges;

@property (strong, nonatomic) RLMNotificationToken *token;

@property (weak, nonatomic) RLMRealm *realm;

@end

@implementation RBQRealmChangeLogger

#pragma mark - Private Class

+ (void)initialize
{
    static bool initialized;
    if (initialized) {
        return;
    }
    initialized = true;
    
    clearManagerCache();
}

#pragma mark - Public Class

+ (instancetype)defaultLogger
{
    return [RBQRealmChangeLogger loggerForRealm:[RLMRealm defaultRealm]];
}

+ (instancetype)loggerForRealm:(RLMRealm *)realm
{
    RBQRealmChangeLogger *logger = cachedRealmChangeLogger(realm.path);
    
    if (!logger) {
        logger = [[self alloc] init];
        
        logger.realm = realm;
        
        [logger registerChangeNotification];
        
        // Associate the logger with the realm so we get dealloc when it does
        objc_setAssociatedObject(realm, &kAssociatedObjectKey, logger, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        
        // Add the manager to the cache
        cacheRealmChangeLogger(logger, realm.path);
    }
    
    return logger;
}

#pragma mark - Public Instance

- (void)didAddObject:(RLMObjectBase *)addedObject
{
    if (addedObject &&
        !addedObject.invalidated) {
        
        [self tokenCheck];
        
        // Save a safe object to use across threads
        RBQSafeRealmObject *safeObject = [RBQSafeRealmObject safeObjectFromObject:addedObject];
        
        RBQEntityChangesObject *entityChangesObject = [self createOrRetrieveEntityChangesForClassName:safeObject.className];
        
        [entityChangesObject didAddSafeObject:safeObject];
    }
}

- (void)didAddObjects:(id<NSFastEnumeration>)addedObjects
{
    if (addedObjects) {
        
        [self tokenCheck];
        
        for (RLMObjectBase *addedObject in addedObjects) {
            
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

- (void)willDeleteObject:(RLMObjectBase *)deletedObject
{
    if (deletedObject &&
        !deletedObject.invalidated) {
        
        [self tokenCheck];
        
        // Save a safe object to use across threads
        RBQSafeRealmObject *safeObject = [RBQSafeRealmObject safeObjectFromObject:deletedObject];
        
        RBQEntityChangesObject *entityChangesObject = [self createOrRetrieveEntityChangesForClassName:safeObject.className];
        
        [entityChangesObject willDeleteSafeObject:safeObject];
    }
}

- (void)willDeleteObjects:(id<NSFastEnumeration>)deletedObjects
{
    if (deletedObjects) {
        
        [self tokenCheck];
        
        for (RLMObjectBase *deletedObject in deletedObjects) {
            
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

- (void)didChangeObject:(RLMObjectBase *)changedObject
{
    if (changedObject &&
        !changedObject.invalidated) {
        
        [self tokenCheck];
        
        // Save a safe object to use across threads
        RBQSafeRealmObject *safeObject = [RBQSafeRealmObject safeObjectFromObject:changedObject];
        
        RBQEntityChangesObject *entityChangesObject = [self createOrRetrieveEntityChangesForClassName:safeObject.className];
        
        [entityChangesObject didChangeSafeObject:safeObject];
    }
}

- (void)didChangeObjects:(id<NSFastEnumeration>)changedObjects
{
    if (changedObjects) {
        
        [self tokenCheck];
        
        for (RLMObjectBase *changedObject in changedObjects) {
            
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
    [self tokenCheck];
    
    if (addedObjects) {
        
        for (RLMObjectBase *addedObject in addedObjects) {
            
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
        
        for (RLMObjectBase *deletedObject in deletedObjects) {
            
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
        
        for (RLMObjectBase *changedObject in changedObjects) {
            
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
    typeof(self) __weak weakSelf = self;
    
    self.token = [self.realm
                  addNotificationBlock:^(NSString *note, RLMRealm *realm) {
                      
                      if ([note isEqualToString:RLMRealmDidChangeNotification]) {
                          
                          // Pass the changes to the RealmNotificationManager
                          [[RBQRealmNotificationManager defaultManager] sendNotificationsWithRealm:realm entityChanges:weakSelf.entityChanges];
                          
                          // Nil the changes collection
                          weakSelf.internalEntityChanges = nil;
                          
                          // Remove the token and nil it so we get dealloc
                          [weakSelf.realm removeNotification:weakSelf.token];
                          weakSelf.token = nil;
                      }
                  }];
}

- (void)tokenCheck
{
    if (!self.token) {
        [self registerChangeNotification];
    }
}

#pragma mark - Helper

- (RBQEntityChangesObject *)createOrRetrieveEntityChangesForClassName:(NSString *)className
{
    if (!className) {
        return nil;
    }
    
    RBQEntityChangesObject *entityChangesObject;
    @synchronized(self.internalEntityChanges) {
        entityChangesObject = self.internalEntityChanges[className];
        
        if (!entityChangesObject) {
            entityChangesObject =
                [RBQEntityChangesObject createEntityChangeObjectWithClassName:className];
        
            self.internalEntityChanges[className] = entityChangesObject;
        }
    }
    
    return entityChangesObject;
}

@end