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

@property (strong, nonatomic) NSMutableArray *addedSafeObjects;
@property (strong, nonatomic) NSMutableArray *deletedSafeObjects;
@property (strong, nonatomic) NSMutableArray *changedSafeObjects;

@property (strong, nonatomic) RLMNotificationToken *token;

@property (strong, nonatomic) NSMapTable *notificationHandlers;

@end

@implementation RBQRealmNotificationManager

#pragma mark - Class

+ (instancetype)defaultManager
{
    static RBQRealmNotificationManager *defaultManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        defaultManager = [[self alloc] init];
        
        // Use the default Realm
        defaultManager.realmPath = [RLMRealm defaultRealm].path;
    });
    return defaultManager;
}

+ (instancetype)managerForRealm:(RLMRealm *)realm
{
    static RBQRealmNotificationManager *defaultManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        defaultManager = [[self alloc] init];
        
        // Use the default Realm
        defaultManager.realmPath = realm.path;
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
        
        [self registerChangeNotification];
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
    token.realmPath = self.realmPath;
    token.block = block;
    [_notificationHandlers setObject:token forKey:token];
    return token;
}

- (void)removeNotification:(RBQNotificationToken *)token
{
    if (token) {
        [_notificationHandlers removeObjectForKey:token];
        token.realmPath = nil;
        token.block = nil;
    }
}

#pragma mark - Public Change Methods

- (void)didAddObject:(RLMObject *)addedObject
{
    // Save a safe object to use across threads
    RBQSafeRealmObject *safeObject = [RBQSafeRealmObject safeObjectFromObject:addedObject];
    
    [self.addedSafeObjects addObject:safeObject];
}

- (void)willDeleteObject:(RLMObject *)deletedObject
{
    // Save a safe object to use across threads
    RBQSafeRealmObject *safeObject = [RBQSafeRealmObject safeObjectFromObject:deletedObject];
    
    [self.deletedSafeObjects addObject:safeObject];
}

- (void)didChangeObject:(RLMObject *)changedObject
{
    // Save a safe object to use across threads
    RBQSafeRealmObject *safeObject = [RBQSafeRealmObject safeObjectFromObject:changedObject];
    
    [self.changedSafeObjects addObject:safeObject];
}

- (void)didAddObjects:(NSArray *)addedObjects
    willDeleteObjects:(NSArray *)deletedObjects
     didChangeObjects:(NSArray *)changedObjects
{
    if (addedObjects) {
        for (RLMObject *addedObject in addedObjects) {
            // Save a safe object to use across threads
            RBQSafeRealmObject *safeObject = [RBQSafeRealmObject safeObjectFromObject:addedObject];
            
            [self.addedSafeObjects addObject:safeObject];
        }
    }
    
    if (deletedObjects) {
        for (RLMObject *deletedObject in deletedObjects) {
            // Save a safe object to use across threads
            RBQSafeRealmObject *safeObject = [RBQSafeRealmObject safeObjectFromObject:deletedObject];
            
            [self.deletedSafeObjects addObject:safeObject];
        }
    }
    
    if (changedObjects) {
        for (RLMObject *changedObject in changedObjects) {
            // Save a safe object to use across threads
            RBQSafeRealmObject *safeObject = [RBQSafeRealmObject safeObjectFromObject:changedObject];
            
            [self.changedSafeObjects addObject:safeObject];
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
    self.token = [[RLMRealm defaultRealm] addNotificationBlock:^(NSString *note, RLMRealm *realm) {
        if ([note isEqualToString:RLMRealmDidChangeNotification]) {
            [self sendNotifications];
        }
    }];
}

#pragma mark - RBQNotification

// Calling this method will broadcast any registered changes
- (void)sendNotifications
{
    // call this realms notification blocks
    for (RBQNotificationToken *token in [_notificationHandlers copy]) {
        if (token.block) {
            token.block(self.addedSafeObjects.copy,
                        self.deletedSafeObjects.copy,
                        self.changedSafeObjects.copy,
                        [RLMRealm realmWithPath:self.realmPath]);
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
        RLMObject *object = [RBQSafeRealmObject objectInRealm:[RLMRealm defaultRealm]
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
        RLMObject *object = [RBQSafeRealmObject objectInRealm:[RLMRealm defaultRealm]
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
        RLMObject *object = [RBQSafeRealmObject objectInRealm:[RLMRealm defaultRealm]
                                               fromSafeObject:safeObject];
        
        if (object) {
            [changedObjects addObject:object];
        }
    }
    
    return changedObjects.copy;
}

@end
