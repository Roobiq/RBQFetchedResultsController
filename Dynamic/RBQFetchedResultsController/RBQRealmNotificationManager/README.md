# RBQRealmNotificationManager
Track RLMObject changes from Realm

#### Note:
If you plan to use this code seperate from https://github.com/Roobiq/RBQFetchedResultsController, then you need to also include https://github.com/Roobiq/RealmUtilities since RBQSafeRealmObject.h is a requirement (All changes from RBQRealmNotificationManager are reported via RBQSafeRealmObject's which are thread-safe representations of RLMObject). 

If I had more time, I would package this and the dependency into its own CocoaPod seperate from RBQFRC, but for now just use:
```
pod "RBQFetchedResultsController"
```
to get everything easily.

For documentation on this class and more info see: https://github.com/Roobiq/RBQFetchedResultsController
