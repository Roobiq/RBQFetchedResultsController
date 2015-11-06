RBQFetchedResultsController
===========================

#####Drop-in replacement for `NSFetchedResultsController` backed by Realm.

##### _Now Supports Realm Swift With A Complete Swift API!_

The `RBQFetchedResultsController` (FRC) is a replacement for `NSFetchedResultsController` when used in conjunction with `RBQRealmNotificationManager` and `RBQRealmChangeLogger`. The controller and delegate follow the same paradigm as `NSFetchedResultsController`, and allow the developer to monitor changes of a `RLMObject` subclass.

`RBQFetchedResultsController` supports tableview sections and implements a drop-in replacement delegate to pass the changes to the tableview for section and row animations.

The Swift API mirrors Objective-C with the following classes:
* `FetchedResultsController`
* `FetchRequest`
* `ChangeLogger`
* `SafeObject`

####Example
Basic todo list application built with [ABFRealmTableViewController](https://github.com/bigfish24/ABFRealmTableViewController) which relies on `RBQFetchedResultsController`:

![Todo List Backed By ABFRealmTableViewController](http://fat.gfycat.com/TinyMagnificentGermanspaniel.gif "Todo List Backed By ABFRealmTableViewController")

####How It Works:

Given that Realm does not yet support more fine-grained or object-level notifications, the FRC works by receiving changes from the `RBQRealmNotificationManager` singleton. The notification manager's role is to pass along changes logged to an instance of `RBQRealmChangeLogger`. Each logger is associated with a Realm on a given thread, which allows the developer to log changes manually or through one of the convenience methods on the `RLMObject` or `RLMRealm` categories. Once the changes are committed and the Realm instance updates, the object level changes will be passed from the logger to the manager, which will in turn rebroadcast these changes to any listeners.

#####For example:

If one was to change a property firstName on a `RLMObject` subclass Person via:

```Objective-C
Person.firstName = @"Adam"; 
```

to broadcast this change would require calling: 

**Objective-C**
```Objective-C
[[RBQRealmChangeLogger defaultLogger] didChangeObject:Person];
```
**Swift**
```Swift
ChangeLogger.defaultLogger.didChangeObject(Person)
```
There are methods for adds, removes, and changes on `RBQRealmChangeLogger`.

Once Realm updates, the logger will receive the update notification from Realm and broadcast `RBQSafeRealmObjects` for any object originally logged to the `RBQRealmNotificationManager`, which will then rebroadcast the changes to any listeners.

**Note: The `RBQSafeRealmObject` is a class to get around the lack of thread-safety with `RLMObject`. Any `RLMObject` with a primary key can be used to create a `RBQSafeRealmObject`, which then can be used across threads and recreated into the `RLMObject` via the primary key.**

The FRC receives the changes from the `RBQRealmNotificationManager` and then identifies changes to sections and rows, which are passed to a tableview controller via the delegate methods:

**Objective-C**
```Objective-C
-(void)controllerWillChangeContent:(RBQFetchedResultsController *)controller;
 
-(void)controller:(RBQFetchedResultsController *)controller
   didChangeObject:(RBQSafeRealmObject *)anObject
       atIndexPath:(NSIndexPath *)indexPath
     forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath;

-(void)controller:(RBQFetchedResultsController *)controller
  didChangeSection:(RBQFetchedResultsSectionInfo *)sectionInfo
           atIndex:(NSUInteger)sectionIndex
     forChangeType:(NSFetchedResultsChangeType)type;

-(void)controllerDidChangeContent:(RBQFetchedResultsController *)controller;
```

**Swift**
```Swift
func controllerWillChangeContent<T: Object>(controller: FetchedResultsController<T>)

func controllerDidChangeObject<T: Object>(controller: FetchedResultsController<T>, anObject: SafeObject<T>, indexPath: NSIndexPath?, changeType: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?)

func controllerDidChangeSection<T:Object>(controller: FetchedResultsController<T>, section: FetchResultsSectionInfo<T>, sectionIndex: UInt, changeType: NSFetchedResultsChangeType)

func controllerDidChangeContent<T: Object>(controller: FetchedResultsController<T>)
```
####Documentation
[Click Here](http://htmlpreview.github.io/?https://raw.githubusercontent.com/Roobiq/RBQFetchedResultsController/master/Documentation/html/index.html)

#####Migrations
Realm by default loads all of the properties defined in your models to all Realm files created by your app, which includes the cache files that the FRC uses internally. As a result, if you need to migrate your models, you will need to call: 
```
setSchemaVersion:forRealmAtPath:withMigrationBlock:
```
for all the paths that correspond to the cache files the FRC has persisted to disk. To simplify getting the paths, there is a class method that retrieves all the paths, which you then iterate over like this:
```Objective-C
NSMutableArray *paths =
    [NSMutableArray arrayWithArray:[RBQFetchedResultsController allCacheRealmPaths]];

/**
 * Add the paths to your main Realm files to the mutable array...
 */
 
for (NSString *path in paths) {
        // Notice setSchemaVersion is set to 1, this is always set manually. It must be
        // higher than the previous version (oldSchemaVersion) or an RLMException is thrown
        [RLMRealm setSchemaVersion:1
                    forRealmAtPath:path
                withMigrationBlock:^(RLMMigration *migration, NSUInteger oldSchemaVersion) {
                    // We haven’t migrated anything yet, so oldSchemaVersion == 0
                    if (oldSchemaVersion < 1) {
                        // Nothing to do!
                        // Realm will automatically detect new properties and removed properties
                        // And will update the schema on disk automatically
                    }
                }];
    }
```

####Installation
RBQFetchedResultsController is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

**Objective-C**
```
pod "RBQFetchedResultsController"
```

**Swift**
```
use_frameworks!

// For Realm 0.96 (use latest)
pod 'SwiftFetchedResultsController'

// For Realm < 0.96
pod 'SwiftFetchedResultsController', '2.3'
```

####Demo

Build and run/test the Example project in Xcode to see `RBQFetchedResultsController` in action. This project uses CocoaPods. If you don't have [CocoaPods](http://cocoapods.org/) installed, grab it with [sudo] gem install cocoapods.

**Objective-C**
```
git clone http://github.com/Roobiq/RBQFetchedResultsController
cd RBQFetchedResultsController/RBQFetchedResultsControllerExample
pod install
open RBQFetchedResultsControllerExample.xcworkspace
```

**Swift**
```
git clone http://github.com/Roobiq/RBQFetchedResultsController
cd RBQFetchedResultsController/SwiftExample
pod install
open RBQFRCSwiftExample.xcworkspace
```

####Current State
The example project includes various functional and unit tests. In addition, the project is used in our [Roobiq](http://www.roobiq.com) app and is quite stable.

Instructions and documentation for the Swift API is forthcoming. Check out the example project in `/SwiftExample` for more details.

**`RLMRealm` and `RLMObject` categories are included that contain methods to simplify calling RBQRealmChangeLogger:**

```Objective-C
// RLMRealm
- (void)addObjectWithNotification:(RLMObject *)object;

- (void)addObjectsWithNotification:(id<NSFastEnumeration>)array;

- (void)addOrUpdateObjectWithNotification:(RLMObject *)object;

- (void)addOrUpdateObjectsFromArrayWithNotification:(id<NSFastEnumeration>)array;

- (void)deleteObjectWithNotification:(RLMObject *)object;

- (void)deleteObjectsWithNotification:(id<NSFastEnumeration>)array;

// RLMObject
typedef void(^RBQChangeNotificationBlock)(id object);

- (void)changeWithNotification:(RBQChangeNotificationBlock)block;

- (void)changeWithNotificationInTransaction:(RBQChangeNotificationBlock)block;
```
####Current Limitations:

1. **The FRC is not currently able to handle RLMObject edits that switch between threads with one thread occurring on a serial queue.**
  
  For example, if an edit to an RLMObject occurs on a background queue (serial or concurrent), and is followed directly after with an edit on the main thread, the FRC can be deadlocked. This limitation is due to the FRC processing all edits serially, with each edit occurring synchronously on the caller thread, and needing to wait on the delegate call backs (which are on the main thread).

  Thus if a main thread edit occurs directly after a background thread edit, the main thread will be waiting on the processing of the background thread to finish in the FRC, while the background thread is waiting on the main thread to perform the dispatched delegate call. 

  **As a result, we recommend to perform all RLMObject edits that are being tracked by an FRC on a background queue (a general best practice anyway).**

2. Finer-grained notifications down to the key path value change would enable even further performance improvements to the FRC.
 
