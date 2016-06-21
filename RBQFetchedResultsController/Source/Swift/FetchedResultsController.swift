//
//  FetchedResultsController.swift
//  RBQFRCSwiftExample
//
//  Created by Adam Fish on 7/23/15.
//  Copyright (c) 2015 Adam Fish. All rights reserved.
//

import Realm
import RealmSwift

/**
This class is used by the FetchedResultsController to pass along section info.
*/
public class FetchResultsSectionInfo<T: Object> {
    
    // MARK: Properties
    
    /**
    The number of objects in the section.
    */
    public var numberOfObjects: UInt {
        return self.rbqFetchedResultsSectionInfo.numberOfObjects
    }
    
    /**
    The objects in the section (generated on-demand and not thread-safe).
    */
    public var objects: Results<T> {
        
        if self.sectionNameKeyPath != nil {
            return self.fetchRequest.fetchObjects().filter("%K == %@", self.sectionNameKeyPath!,self.rbqFetchedResultsSectionInfo.name)
        }
        
        return self.fetchRequest.fetchObjects()
    }
    
    /**
    The name of the section.
    */
    public var name: String {
        return self.rbqFetchedResultsSectionInfo.name
    }
    
    // MARK: Private functions/properties
    
    internal let rbqFetchedResultsSectionInfo: RBQFetchedResultsSectionInfo
    
    internal let fetchRequest: FetchRequest<T>
    
    internal let sectionNameKeyPath: String?
    
    internal init(rbqFetchedResultsSectionInfo: RBQFetchedResultsSectionInfo, fetchRequest: FetchRequest<T>, sectionNameKeyPath: String?) {
        self.rbqFetchedResultsSectionInfo = rbqFetchedResultsSectionInfo
        self.fetchRequest = fetchRequest
        self.sectionNameKeyPath = sectionNameKeyPath
    }
    
}

/**
Delegate to pass along the changes identified by the FetchedResultsController.
*/
public protocol FetchedResultsControllerDelegate: class {
    
    /**
    Indicates that the controller has started identifying changes.
    
    :param: controller controller instance that noticed the change on its fetched objects
    */
    func controllerWillChangeContent<T: Object>(controller: FetchedResultsController<T>)
    
    /**
    Notifies the delegate that a fetched object has been changed due to an add, remove, move, or update. Enables FetchedResultsController change tracking.
    
    Changes are reported with the following heuristics:
    
    On add and remove operations, only the added/removed object is reported. It’s assumed that all objects that come after the affected object are also moved, but these moves are not reported.
    
    A move is reported when the changed attribute on the object is one of the sort descriptors used in the fetch request. An update of the object is assumed in this case, but no separate update message is sent to the delegate.
    
    An update is reported when an object’s state changes, but the changed attributes aren’t part of the sort keys.
    
    :param: controller controller instance that noticed the change on its fetched objects
    :param: anObject changed object represented as a SafeObject for thread safety
    :param: indexPath indexPath of changed object (nil for inserts)
    :param: type indicates if the change was an insert, delete, move, or update
    :param: newIndexPath the destination path for inserted or moved objects, nil otherwise
    */
    
    func controllerDidChangeObject<T: Object>(controller: FetchedResultsController<T>, anObject: SafeObject<T>, indexPath: NSIndexPath?, changeType: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?)
    
    /**
    The fetched results controller reports changes to its section before changes to the fetched result objects.
    
    :param: controller   controller controller instance that noticed the change on its fetched objects
    :param: section      changed section represented as a FetchedResultsSectionInfo object
    :param: sectionIndex the section index of the changed section
    :param: type         indicates if the change was an insert or delete
    */
    func controllerDidChangeSection<T:Object>(controller: FetchedResultsController<T>, section: FetchResultsSectionInfo<T>, sectionIndex: UInt, changeType: NSFetchedResultsChangeType)
    
    /**
    This method is called at the end of processing changes by the controller
    
    :param: controller controller instance that noticed the change on its fetched objects
    */
    func controllerDidChangeContent<T: Object>(controller: FetchedResultsController<T>)

    /**
    This method is called before the controller performs the fetch.

     :param: controller controller instance that will perform the fetch
     */
    func controllerWillPerformFetch<T: Object>(controller: FetchedResultsController<T>)

    /**
    This method is called after the controller successfully fetches objects. It will not be called if the fetchRequest is nil.

    :param: controller controller instance that performed the fetch
    */
    func controllerDidPerformFetch<T: Object>(controller: FetchedResultsController<T>)
}

/**
 Default implementation of the optional methods in FetchedResultsControllerDelegate
 
 Conforming class only has to implement these if it wants to override
 
 :nodoc:
 */
public extension FetchedResultsControllerDelegate {
    // NOOP
    func controllerWillPerformFetch<T: Object>(controller: FetchedResultsController<T>) {}
    // NOOP
    func controllerDidPerformFetch<T: Object>(controller: FetchedResultsController<T>) {}
}

/**
The class is used to monitor changes from a RBQRealmNotificationManager to convert these changes into specific index path or section index changes. Typically this is used to back a UITableView and support animations when items are inserted, deleted, or changed.
*/
public class FetchedResultsController<T: Object> {
    
    // MARK: Class Functions
    
    /**
    Deletes the cached section information with the given name
    
    If name is not nil, then the cache will be cleaned, but not deleted from disk.
    
    If name is nil, then all caches will be deleted by removing the files from disk.
    
    :warning:  If clearing all caches (name is nil), it is recommended to do this in didFinishLaunchingWithOptions: in AppDelegate because Realm files cannot be deleted from disk safely, if there are strong references to them.
    
    :param: name The name of the cache file to delete. If name is nil, deletes all cache files.
    */
    public class func deleteCache(cacheName: String) {
        RBQFetchedResultsController.deleteCacheWithName(cacheName)
    }
    
    /**
    Retrieves all the paths for the Realm files being used as FRC caches on disk.
    
    The typical use case for this method is to use the paths to perform migrations in AppDelegate. The FRC cache files need to be migrated along with your other Realm files because by default Realm includes all of the properties defined in your model in all Realm files. Thus the FRC cache files will throw an exception if they are not migrated. Call setSchemaVersion:forRealmAtPath:withMigrationBlock: for each path returned in the array.
    
    :returns: NSArray of NSStrings representing the paths on disk for all FRC cache Realm files
    */
    public class func allCacheRealmPaths() -> [String] {
        
        var paths = [String]()
        
        let allPaths = RBQFetchedResultsController.allCacheRealmPaths()
        
        for aPath: AnyObject in allPaths {
            
            if let path = aPath as? String {
                
                paths.append(path)
            }
        }
        
        return paths
    }
    
    // MARK: Initializer
    
    /**
    Constructor method to initialize the controller
    
    :warning: Specify a cache name if deletion of the cache later on is necessary
    
    :param: fetchRequest       the FetchRequest for the controller
    :param: sectionNameKeyPath A key path on result objects that returns the section name. Pass nil to indicate that the controller should generate a single section. If this key path is not the same as that specified by the first sort descriptor in fetchRequest, they must generate the same relative orderings.
    :param: name               the cache name (if nil, cache will not be persisted and built using an in-memory Realm)
    
    :returns: A new instance of FetchedResultsController
    */
    public init(fetchRequest: FetchRequest<T>, sectionNameKeyPath: String?, cacheName: String?) {
        
        self.fetchRequest = fetchRequest
        
        self.rbqFetchedResultsController = RBQFetchedResultsController(fetchRequest: fetchRequest.rbqFetchRequest, sectionNameKeyPath: sectionNameKeyPath, cacheName: cacheName)
        
        self.delegateProxy = DelegateProxy(delegate: self)
        
        self.rbqFetchedResultsController.delegate = self.delegateProxy!
    }
    
    // MARK: Properties
    
    /// The fetch request for the controller
    public let fetchRequest: FetchRequest<T>
    
    /// The section name key path used to create the sections. Can be nil if no sections.
    public var sectionNameKeyPath: String? {
        return self.rbqFetchedResultsController.sectionNameKeyPath
    }
    
    /// The delegate to pass the index path and section changes to.
    weak public var delegate: FetchedResultsControllerDelegate?
    
    /// The name of the cache used internally to represent the tableview structure.
    public var cacheName: String? {
        return self.rbqFetchedResultsController.cacheName
    }
    
    /// All the objects that match the fetch request.
    public var fetchedObjects: Results<T> {
        return self.fetchRequest.fetchObjects()
    }
    
    /// Returns all the section titles if using a section name key path
    public var sectionIndexTitles: [String]? {
        return self.rbqFetchedResultsController.sectionIndexTitles
    }
    
    // MARK: Functions
    
    /**
    Method to tell the controller to perform the fetch
    
    :returns: Indicates if the fetch was successful
    */
    public func performFetch() -> Bool {
        return self.rbqFetchedResultsController.performFetch()
    }
    
    /**
    Call this method to force the cache to be rebuilt.
    
    A potential use case would be to call this in a @catch after trying to call endUpdates for the table view. If an exception is thrown, then the cache will be rebuilt and you can call reloadData on the table view.
    */
    public func reset() {
        self.rbqFetchedResultsController.reset()
    }
    /**
    Call these method to registerChangeNotifications or unregisterNotifications 

    A potential use case would be if you have many stacked views and only want certain view to receive notifications.
     
    */

    public func unregisterChangeNotifications() {
        self.rbqFetchedResultsController.unregisterChangeNotifications()
    }

    public func registerChangeNotifications() {
        self.rbqFetchedResultsController.registerChangeNotifications()
    }

    /**
    Method to retrieve the number of rows for a given section index
    
    :param: index section index
    
    :returns: number of rows in the section
    */
    public func numberOfRowsForSectionIndex(index: Int) -> Int {
        return self.rbqFetchedResultsController.numberOfRowsForSectionIndex(index)
    }
    
    /**
    Method to retrieve the number of sections represented by the fetch request
    
    :returns: number of sections
    */
    public func numberOfSections() -> Int {
        return self.rbqFetchedResultsController.numberOfSections()
    }
    
    /**
    Method to retrieve the title for a given section index
    
    :param: section section index
    *
    :returns: The title of the section
    */
    public func titleForHeaderInSection(section: Int) -> String {
        return self.rbqFetchedResultsController.titleForHeaderInSection(section)
    }
    
    /**
    Method to retrieve the section index given a section name
    
    :warning: Returns NSNotFound if there is not a section with the given name
    
    :param: sectionName the name of the section
    
    :returns: the index of the section (returns NSNotFound if no section with the given name)
    */
    public func sectionIndexForSectionName(sectionName: String) -> UInt {
        return self.rbqFetchedResultsController.sectionIndexForSectionName(sectionName)
    }
    
    /**
    Retrieve the SafeObject for a given index path
    
    :param: indexPath the index path of the object
    
    :returns: SafeObject
    */
    public func safeObjectAtIndexPath(indexPath: NSIndexPath) -> SafeObject<T>? {
        
        if let rbqSafeObject = self.rbqFetchedResultsController.safeObjectAtIndexPath(indexPath) {
            let safeObject = SafeObject<T>(rbqSafeRealmObject: rbqSafeObject)
            
            return safeObject
        }
        
        return nil
    }
    
    /**
    Retrieve the Object for a given index path
    
    :warning: Returned object is not thread-safe.
    
    :param: indexPath the index path of the object
    
    :returns: Object
    */
    public func objectAtIndexPath(indexPath: NSIndexPath) -> T? {
        
        if let rlmObject: AnyObject = self.rbqFetchedResultsController.objectAtIndexPath(indexPath) {
            
            return unsafeBitCast(rlmObject, T.self)
        }
        
        return nil
    }
    
    /**
    Retrieve the index path for a safe object in the fetch request
    
    :param: safeObject an instance of SafeObject
    
    :returns: index path of the object
    */
    public func indexPathForSafeObject(safeObject: SafeObject<T>) -> NSIndexPath? {
        return self.rbqFetchedResultsController.indexPathForSafeObject(safeObject.rbqSafeRealmObject)
    }
    
    /**
    Retrieve the index path for a Object in the fetch request
    
    :param: object an instance of Object
    
    :returns: index path of the object
    */
    public func indexPathForObject(object: T) -> NSIndexPath? {
        return self.rbqFetchedResultsController.indexPathForObject(object)
    }
    
    /**
    Convenience method to safely update the fetch request for an existing FetchResultsController
    
    :param: fetchRequest       a new instance of FetchRequest
    :param: sectionNameKeyPath the section name key path for this fetch request (if nil, no sections will be shown)
    :param: performFetch       indicates whether you want to immediately performFetch using the new fetch request to rebuild the cache
    */
    public func updateFetchRequest(fetchRequest: FetchRequest<T>, sectionNameKeyPath: String?, performFetch: Bool) {
        self.rbqFetchedResultsController.updateFetchRequest(fetchRequest.rbqFetchRequest, sectionNameKeyPath: sectionNameKeyPath, andPerformFetch: performFetch)
    }
    
    // MARK: Private functions/properties
    
    internal let rbqFetchedResultsController: RBQFetchedResultsController
    
    internal var delegateProxy: DelegateProxy?
}

// Internal Proxy To Manage Converting The Objc Delegate
extension FetchedResultsController: DelegateProxyProtocol {

    func controllerWillChangeContent(controller: RBQFetchedResultsController!) {
        if let delegate = self.delegate {
            
            delegate.controllerWillChangeContent(self)
        }
    }
    
    func controller(controller: RBQFetchedResultsController!, didChangeObject anObject: RBQSafeRealmObject!, atIndexPath indexPath: NSIndexPath!, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath!) {
        
        if let delegate = self.delegate {
            
            let safeObject = SafeObject<T>(rbqSafeRealmObject: anObject)
            
            delegate.controllerDidChangeObject(self, anObject: safeObject, indexPath: indexPath, changeType: type, newIndexPath: newIndexPath)
        }
    }
    
    func controller(controller: RBQFetchedResultsController!, didChangeSection section: RBQFetchedResultsSectionInfo!, atIndex sectionIndex: UInt, forChangeType type: NSFetchedResultsChangeType) {
        
        if let delegate = self.delegate {
            
            let sectionInfo = FetchResultsSectionInfo<T>(rbqFetchedResultsSectionInfo: section, fetchRequest: self.fetchRequest, sectionNameKeyPath: self.sectionNameKeyPath)
            
            delegate.controllerDidChangeSection(self, section: sectionInfo, sectionIndex: sectionIndex, changeType: type)
        }
    }
    
    func controllerDidChangeContent(controller: RBQFetchedResultsController!) {
        if let delegate = self.delegate {
            
            delegate.controllerDidChangeContent(self)
        }
    }

    func controllerWillPerformFetch(controller: RBQFetchedResultsController!) {
        if let delegate = self.delegate {
            delegate.controllerWillPerformFetch(self)
        }

    }

    func controllerDidPerformFetch(controller: RBQFetchedResultsController!) {
        if let delegate = self.delegate {

            delegate.controllerDidPerformFetch(self)
        }

    }
}

// Internal Proxy To Manage Converting The Objc Delegate
internal protocol DelegateProxyProtocol: class {
    func controllerWillChangeContent(controller: RBQFetchedResultsController!)
    
    func controller(controller: RBQFetchedResultsController!, didChangeObject anObject: RBQSafeRealmObject!, atIndexPath indexPath: NSIndexPath!, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath!)
    
    func controller(controller: RBQFetchedResultsController!, didChangeSection section: RBQFetchedResultsSectionInfo!, atIndex sectionIndex: UInt, forChangeType type: NSFetchedResultsChangeType)
    
    func controllerDidChangeContent(controller: RBQFetchedResultsController!)

    func controllerWillPerformFetch(controller: RBQFetchedResultsController!)

    func controllerDidPerformFetch(controller: RBQFetchedResultsController!)
}

// Internal Proxy To Manage Converting The Objc Delegate
internal class DelegateProxy: NSObject, RBQFetchedResultsControllerDelegate {
    
    weak internal var delegate: DelegateProxyProtocol?
    
    init(delegate: DelegateProxyProtocol) {
        self.delegate = delegate
    }
    
    // <RBQFetchedResultsControllerDelegate>
    @objc func controllerWillChangeContent(controller: RBQFetchedResultsController) {
        self.delegate?.controllerWillChangeContent(controller)
    }
    
    @objc func controller(controller: RBQFetchedResultsController, didChangeObject anObject: RBQSafeRealmObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        
        self.delegate?.controller(controller, didChangeObject: anObject, atIndexPath: indexPath, forChangeType: type, newIndexPath: newIndexPath)
    }
    
    @objc func controller(controller: RBQFetchedResultsController, didChangeSection section: RBQFetchedResultsSectionInfo, atIndex sectionIndex: UInt, forChangeType type: NSFetchedResultsChangeType) {
        
        self.delegate?.controller(controller, didChangeSection: section, atIndex: sectionIndex, forChangeType: type)
    }
    
    @objc func controllerDidChangeContent(controller: RBQFetchedResultsController) {
        self.delegate?.controllerDidChangeContent(controller)
    }

    @objc func controllerWillPerformFetch(controller: RBQFetchedResultsController) {
        self.delegate?.controllerWillPerformFetch(controller)
    }

    @objc func controllerDidPerformFetch(controller: RBQFetchedResultsController) {
        self.delegate?.controllerDidPerformFetch(controller)
    }

}