RBQFetchedResultsController
===========================

#####Drop-in replacement for `NSFetchedResultsController` backed by RealmDB.

The `RBQFetchedResultsController` (FRC) is a replacement for `NSFetchedResultsController` when used in conjunction with `RBQRealmNotificationManager` and `RBQRealmChangeLogger`. The controller and delegate follow the same paradigm as `NSFetchedResultsController`, and allow the developer to monitor changes of a `RLMObject` subclass.

`RBQFetchedResultsController` supports tableview sections and implements a drop-in replacement delegate to pass the changes to the tableview for section and row animations.

####How It Works:

Given that Realm does not yet support more fine-grained or object-level notifications, the FRC works by receiving changes from the `RBQRealmNotificationManager` singleton. The notification manager's role is to pass along changes logged to an instance of `RBQRealmChangeLogger`. Each logger is associated with a Realm on a given thread, which allows the developer to log changes manually or through one of the convenience methods on the RLMObject or RLMRealm categories. Once the changes are committed and the Realm instance updates, the object level changes will be passed from the logger to the manager, which will in turn rebroadcast these changes to any listeners.

#####For example:

If one was to change a property firstName on a `RLMObject` subclass Person via:

```Objective-C
Person.firstName = @"Adam"; 
```

to broadcast this change would require calling: 

```Objective-C
[[RBQRealmChangeLogger defaultLogger] didChangeObject:Person];
```
There are methods for adds, removes, and changes on `RBQRealmChangeLogger`.

Once Realm updates, the logger will receive the update notification from Realm and broadcast `RBQSafeRealmObjects` for any object originally logged to the RBQRealmNotificationManager, which will then rebroadcast the changes to any listeners.

**Note: The RBQSafeRealmObject is a class to get around the lack of thread-safety with RLMObject. Any RLMObject with a primary key can be used to create a RBQSafeRealmObject, which then can be used across threads and recreated into the RLMObject via the primary key.**

The FRC receives the changes from the `RBQRealmNotificationManager` and then identifies changes to sections and rows, which are passed to a tableview controller via the delegate methods:

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
####Installation
RBQFetchedResultsController is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

    pod "RBQFetchedResultsController"

####Demo

Build and run/test the Example project in Xcode to see `RBQFetchedResultsController` in action. This project uses CocoaPods. If you don't have [CocoaPods](http://cocoapods.org/) installed, grab it with [sudo] gem install cocoapods.

```
git clone http://github.com/Roobiq/RBQFetchedResultsController
cd RBQFetchedResultsController/RBQFetchedResultsControllerExample
pod install
open RBQFetchedResultsControllerExample.xcworkspace
```

#####Requirements

* iOS 7+
* Xcode 6

####Current Limitations:

~~1. The `RBQRealmNotificationManager` requires manually logging of changes. A better solution would be to abstract this away by creating a `RLMRealm` and `RLMObject` subclass that performs the log whenever the key path value is changed on the object or an object is added or deleted from Realm.~~

**Note: `RLMRealm` and `RLMObject` categories are included that contain methods to simplify calling RBQRealmChangeLogger:**

```Objective-C
// RLMRealm
- (void)addObjectWithNotification:(RLMObject *)object;

- (void)addObjectsWithNotification:(id<NSFastEnumeration>)array;

- (void)addOrUpdateObjectWithNotification:(RLMObject *)object;

- (void)addOrUpdateObjectsFromArrayWithNotification:(id)array;

- (void)deleteObjectWithNotification:(RLMObject *)object;

- (void)deleteObjectsWithNotification:(id)array;

// RLMObject
typedef void(^RBQChangeNotificationBlock)(RLMObject *object);

- (void)changeWithNotification:(RBQChangeNotificationBlock)block;

- (void)changeWithNotificationInTransaction:(RBQChangeNotificationBlock)block;
```

2. Finer-grained notifications down to the key path value change would enable even further performance improvements to the FRC.
 
