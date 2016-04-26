RBQFetchedResultsController
===========================
[![CocoaPods](https://img.shields.io/cocoapods/v/RBQFetchedResultsController.svg)]()
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)

#####Drop-in replacement for `NSFetchedResultsController` backed by Realm.

##### _Now Supports Realm Swift With A Complete Swift API!_

The `RBQFetchedResultsController` (FRC) is a replacement for `NSFetchedResultsController` that works with [Realm](http://www.realm.io). The controller and delegate follow the same paradigm as `NSFetchedResultsController`, and allow the developer to monitor changes of a `RLMObject` subclass.

`RBQFetchedResultsController` supports tableview sections and implements a drop-in replacement delegate to pass the changes to the tableview for section and row animations.

**Realm class requires a primary key to work with `RBQFetchedResultsController`**

The Swift API mirrors Objective-C with the following classes:
* `FetchedResultsController`
* `FetchRequest`
* `SafeObject`

####Example
Basic todo list application built with [ABFRealmTableViewController](https://github.com/bigfish24/ABFRealmTableViewController) which relies on `RBQFetchedResultsController`:

![Todo List Backed By ABFRealmTableViewController](http://fat.gfycat.com/TinyMagnificentGermanspaniel.gif "Todo List Backed By ABFRealmTableViewController")

####How It Works:

**Starting with v4.0 and Realm v0.99, `RBQFetchedResultsController` works automatically with Realm's fine-grained notification support. It is recommended to use Realm's API directly instead of `RBQFetchedResultsController` unless you need support for sections.**

Changes produced by Realm will be reprocessed to calculate changes accomodating any sections. These changes will then be passed to a delegate:

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
**Starting with v4.0, `RBQFetchedResultsController` now only uses the schemas specific to its internal Realm for section caching. This means handling migrations of the cache Realm is no longer necessary!**

####Installation
`RBQFetchedResultsController` is available through [CocoaPods](http://cocoapods.org) or [Carthage](https://github.com/Carthage/Carthage). 

####Cocoapods
To install it, simply add the following line to your Podfile:

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

Then run `pod install`.

####Carthage
To install it, simply add the following line to your Cartfile:

**Objective-C**
```
github "Roobiq/RBQFetchedResultsController"
```
**Swift**
```
github "Roobiq/SwiftFetchedResultsController"
```

Then run `carthage update` and drag `RBQFetchedResultsController.framework` or `SwiftFetchedResultsController.framework` from the appropriate platform directory in `Carthage/Build/` to the "Linked Frameworks and Libraries" section of your Xcode project’s "General" settings.

####Demo

Build and run/test the Example project in Xcode to see `RBQFetchedResultsController` in action. This project uses CocoaPods. If you don't have [CocoaPods](http://cocoapods.org/) installed, grab it with [sudo] gem install cocoapods.

**Objective-C**
```
git clone http://github.com/Roobiq/RBQFetchedResultsController
git submodule init
git submodule update
cd Examples/ObjC
pod install
open RBQFetchedResultsControllerExample.xcworkspace
```

**Swift**
```
git clone http://github.com/Roobiq/RBQFetchedResultsController
git submodule init
git submodule update
cd Examples/Swift
pod install
open RBQFRCSwiftExample.xcworkspace
```

**Note:** the example projects install the framework by directly including the source files and using Cocoapods to install Realm. There are also example projects that test/demonstrate installation of the framework with Cocoapods and Carthage. For the Cocoapods install example apps (`ObjC-cocoapods`/`Swift-cocoapods`) the framework is installed as a development pod, referencing the local podspec and source files. Follow the same instructions as above, since the `pod install` will simply include the framework.

For the Carthage example apps (`ObjC-carthage`/`Swift-carthage`), you must run `carthage update` after `git submodule update` in the steps above so that Carthage can build the Realm framework(s) locally. The example project then uses the `RBQFetchedResultsController.xcodeproj` directly in the same way as you would the resulting framework produced by Carthage.

####Current State
The example project includes various functional and unit tests. In addition, the project is used in our [Roobiq](http://www.roobiq.com) app and is quite stable.
