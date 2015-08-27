//
//  FetchedResultsController.swift
//  RBQFRCSwiftExample
//
//  Created by Adam Fish on 7/23/15.
//  Copyright (c) 2015 Adam Fish. All rights reserved.
//

import Realm
import RealmSwift

public class FetchResultsSectionInfo<T: Object> {
    
    internal let rbqFetchedResultsSectionInfo: RBQFetchedResultsSectionInfo
    
    internal let fetchRequest: FetchRequest<T>
    
    internal let sectionNameKeyPath: String?
    
    /**
    *  The number of objects in the section.
    */
    public var numberOfObjects: UInt {
        return self.rbqFetchedResultsSectionInfo.numberOfObjects
    }
    
    /**
    *  The objects in the section (generated on-demand and not thread-safe).
    */
    public var objects: Results<T> {
        
        if self.sectionNameKeyPath != nil {
            return self.fetchRequest.fetchObjects().filter("%K == %@", self.sectionNameKeyPath!,self.rbqFetchedResultsSectionInfo.name)
        }
        
        return self.fetchRequest.fetchObjects()
    }
    
    /**
    *  The name of the section.
    */
    public var name: String {
        return self.rbqFetchedResultsSectionInfo.name
    }
    
    internal init(rbqFetchedResultsSectionInfo: RBQFetchedResultsSectionInfo, fetchRequest: FetchRequest<T>, sectionNameKeyPath: String?) {
        self.rbqFetchedResultsSectionInfo = rbqFetchedResultsSectionInfo
        self.fetchRequest = fetchRequest
        self.sectionNameKeyPath = sectionNameKeyPath
    }
    
}

public protocol FetchedResultsControllerDelegate {
    /**
    *  Indicates that the controller has started identifying changes.
    *
    *  @param controller controller instance that noticed the change on its fetched objects
    */
    func controllerWillChangeContent<T: Object>(controller: FetchedResultsController<T>)
    
    /**
    *  Notifies the delegate that a fetched object has been changed due to an add, remove, move, or update. Enables RBQFetchedResultsController change tracking.
    *
    *  Changes are reported with the following heuristics:
    *
    *  On add and remove operations, only the added/removed object is reported. It’s assumed that all objects that come after the affected object are also moved, but these moves are not reported.
    *
    *  A move is reported when the changed attribute on the object is one of the sort descriptors used in the fetch request. An update of the object is assumed in this case, but no separate update message is sent to the delegate.
    *
    *  An update is reported when an object’s state changes, but the changed attributes aren’t part of the sort keys.
    *
    *  @param controller controller instance that noticed the change on its fetched objects
    *  @param anObject changed object represented as a RBQSafeRealmObject for thread safety
    *  @param indexPath indexPath of changed object (nil for inserts)
    *  @param type indicates if the change was an insert, delete, move, or update
    *  @param newIndexPath the destination path for inserted or moved objects, nil otherwise
    */
    
    func controllerDidChangeObject<T: Object>(controller: FetchedResultsController<T>, anObject: SafeObject<T>, indexPath: NSIndexPath?, changeType: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?)
    
    /**
    *  The fetched results controller reports changes to its section before changes to the fetched result objects.
    *
    *  @param controller   controller controller instance that noticed the change on its fetched objects
    *  @param section      changed section represented as a RBQFetchedResultsSectionInfo object
    *  @param sectionIndex the section index of the changed section
    *  @param type         indicates if the change was an insert or delete
    */
    func controllerDidChangeSection<T:Object>(controller: FetchedResultsController<T>, section: FetchResultsSectionInfo<T>, sectionIndex: UInt, changeType: NSFetchedResultsChangeType)
    
    /**
    *  This method is called at the end of processing changes by the controller
    *
    *  @param controller controller instance that noticed the change on its fetched objects
    */
    func controllerDidChangeContent<T: Object>(controller: FetchedResultsController<T>)
}

public class FetchedResultsController<T: Object>: DelegateProxyProtocol {
    
    internal let rbqFetchedResultsController: RBQFetchedResultsController
    
    internal var delegateProxy: DelegateProxy?
    
    public let fetchRequest: FetchRequest<T>
    
    public var sectionNameKeyPath: String? {
        return self.rbqFetchedResultsController.sectionNameKeyPath
    }
    
    public var delegate: FetchedResultsControllerDelegate?
    
    public var cacheName: String? {
        return self.rbqFetchedResultsController.cacheName
    }
    
    public var fetchedObjects: Results<T> {
        return self.fetchRequest.fetchObjects()
    }
    
    public init(fetchRequest: FetchRequest<T>, sectionNameKeyPath: String?, cacheName: String?) {
        
        self.fetchRequest = fetchRequest
        
        self.rbqFetchedResultsController = RBQFetchedResultsController(fetchRequest: fetchRequest.rbqFetchRequest, sectionNameKeyPath: sectionNameKeyPath, cacheName: cacheName)
        
        self.delegateProxy = DelegateProxy(delegate: self)
        
        self.rbqFetchedResultsController.delegate = self.delegateProxy!
    }
    
    public class func deleteCache(cacheName: String) {
        RBQFetchedResultsController.deleteCacheWithName(cacheName)
    }
    
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
    
    public func performFetch() -> Bool {
        return self.rbqFetchedResultsController.performFetch()
    }
    
    public func reset() {
        self.rbqFetchedResultsController.reset()
    }
    
    public func numberOfRowsForSectionIndex(index: Int) -> Int {
        return self.rbqFetchedResultsController.numberOfRowsForSectionIndex(index)
    }
    
    public func numberOfSections() -> Int {
        return self.rbqFetchedResultsController.numberOfSections()
    }
    
    public func titleForHeaderInSection(section: Int) -> String {
        return self.rbqFetchedResultsController.titleForHeaderInSection(section)
    }
    
    public func sectionIndexForSectionName(sectionName: String) -> UInt {
        return self.rbqFetchedResultsController.sectionIndexForSectionName(sectionName)
    }
    
    public func safeObjectAtIndexPath(indexPath: NSIndexPath) -> SafeObject<T>? {
        
        let rbqSafeObject = self.rbqFetchedResultsController.safeObjectAtIndexPath(indexPath)
        
        let safeObject = SafeObject<T>(rbqSafeRealmObject: rbqSafeObject)
        
        return safeObject
    }
    
    public func objectAtIndexPath(indexPath: NSIndexPath) -> T? {
        
        if let rlmObject: AnyObject = self.rbqFetchedResultsController.objectAtIndexPath(indexPath) {
            
            return unsafeBitCast(rlmObject, T.self)
        }
        
        return nil
    }
    
    public func indexPathForSafeObject(safeObject: SafeObject<T>) -> NSIndexPath? {
        return self.rbqFetchedResultsController.indexPathForSafeObject(safeObject.rbqSafeRealmObject)
    }
    
    public func indexPathForObject(object: T) -> NSIndexPath? {
        return self.rbqFetchedResultsController.indexPathForObject(object)
    }
    
    public func updateFetchRequest(fetchRequest: FetchRequest<T>, sectionNameKeyPath: String, performFetch: Bool) {
        self.rbqFetchedResultsController.updateFetchRequest(fetchRequest.rbqFetchRequest, sectionNameKeyPath: sectionNameKeyPath, andPeformFetch: performFetch)
    }
}

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
}

internal protocol DelegateProxyProtocol {
    func controllerWillChangeContent(controller: RBQFetchedResultsController!)
    
    func controller(controller: RBQFetchedResultsController!, didChangeObject anObject: RBQSafeRealmObject!, atIndexPath indexPath: NSIndexPath!, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath!)
    
    func controller(controller: RBQFetchedResultsController!, didChangeSection section: RBQFetchedResultsSectionInfo!, atIndex sectionIndex: UInt, forChangeType type: NSFetchedResultsChangeType)
    
    func controllerDidChangeContent(controller: RBQFetchedResultsController!)
}

internal class DelegateProxy: NSObject, RBQFetchedResultsControllerDelegate {
    
    internal let delegate: DelegateProxyProtocol
    
    init(delegate: DelegateProxyProtocol) {
        self.delegate = delegate
    }
    
    /// <RBQFetchedResultsControllerDelegate>
    ///
    @objc func controllerWillChangeContent(controller: RBQFetchedResultsController!) {
        self.delegate.controllerWillChangeContent(controller)
    }
    
    @objc func controller(controller: RBQFetchedResultsController!, didChangeObject anObject: RBQSafeRealmObject!, atIndexPath indexPath: NSIndexPath!, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath!) {
        
        self.delegate.controller(controller, didChangeObject: anObject, atIndexPath: indexPath, forChangeType: type, newIndexPath: newIndexPath)
    }
    
    @objc func controller(controller: RBQFetchedResultsController!, didChangeSection section: RBQFetchedResultsSectionInfo!, atIndex sectionIndex: UInt, forChangeType type: NSFetchedResultsChangeType) {
        
        self.delegate.controller(controller, didChangeSection: section, atIndex: sectionIndex, forChangeType: type)
    }
    
    @objc func controllerDidChangeContent(controller: RBQFetchedResultsController!) {
        self.delegate.controllerDidChangeContent(controller)
    }
}