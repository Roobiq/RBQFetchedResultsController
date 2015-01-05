RBQFetchedResultsController
===========================

#####Non-optimal but drop-in replacement for `NSFetchedResultsController` backed by RealmDB.

The `RBQFetchedResultsController` (FRC) is a replacement for `NSFetchedResultsController` when used in conjunction with `RBQRealmNotificationManager`. The controller and delegate follow the same paradigm as `NSFetchedResultsController`, and allow the developer to monitor changes of a `RLMObject` subclass.

`RBQFetcheResultsController` supports tableview sections and implements a drop-in replacement delegate to pass the changes to the tableview for section and row animations.

####How It Works:

Given that Realm does not yet support more fine-grained or object-level notifications, the FRC works by receiving changes from the `RBQRealmNotificationManager`. The notification manager's role is to allow the developer to log changes manually to the manager, which will in turn rebroadcast these changes to any listeners. 

#####For example:

If one was to change a property firstName on a `RLMObject` subclass Person via:

```Objective-C
Person.firstName = @"Adam"; 
```

to broadcast this change would require calling: 

```Objective-C
[[RBQRealmNotificationManager defaultManager] didChangeObject:Person];
```
There are methods for adds, removes, and changes on `RBQRealmNotificationManager`.

Once Realm updates, the notification manager will receive the notification from Realm and broadcast `RBQSafeRealmObjects` for any object originally logged.

**_Note: The RBQSafeRealmObject is a class to get around the lack of thread-safety with RLMObject. Any RLMObject with a primary key can be used to create a RBQSafeRealmObject, which then can be used across threads and recreated into the RLMObject via the primary key._**

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

####Demo

Build and run/test the Example project in Xcode to see `RBQFetchedResultsController` in action. If you don't have [CocoaPods](http://cocoapods.org/) installed, grab it with [sudo] gem install cocoapods.

```
cd RBQFetchedResultsControllerExample
pod install
open RBQFetchedResultsControllerExample.xcworkspace
```

#####Requirements

* iOS 7+
* Xcode 6

####Current Limitations:

1. The FRC performance degrades as the result set grows. ~1000 rows or less results in acceptable performance in testing from iPhone 4s and greater. The bottleneck is having to iterate through all the `RLMResults` after every change to recreate the section information. If Realm implemented a method to retrieve all of the distinct values for a keypath (i.e. the section keypath), this would allow prevent the need to iterate over every result (i.e. with all the section keypath values, individual `RLMResults` could be created for each section, to identify the number of sections and rows within each section without iterating over every object within each `RLMResults`).

2. The `RBQRealmNotificationManager` requires manually logging of changes. A better solution would be to abstract this away by creating a `RLMRealm` and `RLMObject` subclass that performs the log whenever the keyPath value is changed on the object of an object is added or deleted from Realm.

3. Finer-grained notifications down to the keyPath value change would enable even furhter performance improvements to the FRC. This should be possible if #2 solution above is implemented as logging value changes wouldn't require developer input.
 
