//
//  FetchRequest.swift
//  RBQFRCSwiftExample
//
//  Created by Adam Fish on 7/23/15.
//  Copyright (c) 2015 Adam Fish. All rights reserved.
//

import Realm
import RealmSwift

/**
This class is used by the FetchedResultsController to represent the properties of the fetch. The FetchRequest is specific to one Object and uses an NSPredicate and array of SortDescriptors to define the query.
*/
public class FetchRequest<T: Object> {
    
    // MARK: Initializers
    
    /**
    Constructor method to create a fetch request for a given entity name in a specific Realm.
    
    :param: realm      Realm in which the Object is persisted (if passing in-memory Realm, make sure to keep a strong reference elsewhere since fetch request only stores the path)
    :param predicate  NSPredicate that represents the search query
    
    :returns: A new instance of FetchRequest
    */
    public init(realm: Realm, predicate: NSPredicate) {
        let entityName = T.className()
        
        self.realmConfiguration = realm.configuration
        
        let rlmConfiguration: RLMRealmConfiguration = Realm.toRLMConfiguration(realm.configuration)
        
        let rlmRealm = RLMRealm(configuration: rlmConfiguration, error: nil)
        
        self.rbqFetchRequest = RBQFetchRequest(entityName: entityName, inRealm: rlmRealm, predicate: predicate)
    }
    
    // MARK: Properties
    
    /// Object class name for the fetch request
    public var entityName: String {
        return self.rbqFetchRequest.entityName
    }
    
    /// The Realm in which the entity for the fetch request is persisted.
    public var realm: Realm {
        return Realm(configuration: self.realmConfiguration, error: nil)!
    }
    
    /// The configuration object used to create an instance of Realm for the fetch request
    public let realmConfiguration: Realm.Configuration
    
    /// Predicate supported by Realm
    ///
    /// http://realm.io/docs/cocoa/0.89.2/#querying-with-predicates
    public var predicate: NSPredicate? {
        get {
            return self.rbqFetchRequest.predicate
        }
        set {
            self.rbqFetchRequest.predicate = predicate
        }
        
    }
    
    /// Array of SortDescriptors
    ///
    /// http://realm.io/docs/cocoa/0.89.2/#ordering-results
    public var sortDescriptors: [SortDescriptor] {
        get {
            var sortDescriptors = [SortDescriptor]()
            
            for sortDesc: AnyObject in self.rbqFetchRequest.sortDescriptors {
                
                if let rlmSortDesc = sortDesc as? RLMSortDescriptor {
                    
                    sortDescriptors.append(SortDescriptor(property: rlmSortDesc.property, ascending: rlmSortDesc.ascending))
                }
            }
            
            return sortDescriptors
        }
        set {
            
            var rbqSortDescriptors = [AnyObject]()
            
            for sortDesc in newValue {
                
                let rlmSortDesc = RLMSortDescriptor(property: sortDesc.property, ascending: sortDesc.ascending)
                
                rbqSortDescriptors.append(rlmSortDesc)
            }
            
            self.rbqFetchRequest.sortDescriptors = rbqSortDescriptors
        }
    }
    
    // MARK: Functions
    
    /**
    Retrieve all the Objects for this fetch request in its realm.
    
    @return Results for all the objects in the fetch request (not thread-safe).
    */
    public func fetchObjects() -> Results<T> {
        
        var fetchResults = self.realm.objects(T)
        
        // If we have a predicate use it
        
        if let predicate = self.predicate {
            fetchResults = fetchResults.filter(predicate)
        }
        
        // If we have sort descriptors then use them
        if (self.sortDescriptors.count > 0) {
            fetchResults = fetchResults.sorted(self.sortDescriptors)
        }
        
        return fetchResults
    }
    
    /**
    Should this object be in our fetch results?
    
    Intended to be used by the FetchedResultsController to evaluate incremental changes. For
    simple fetch requests this just evaluates the NSPredicate, but subclasses may have a more
    complicated implementaiton.
    
    :param: object Realm object of appropriate type
    
    :returns: YES if performing fetch would include this object
    */
    public func evaluateObject(object: T) -> Bool {
        
        if let predicate = self.predicate {
            return predicate.evaluateWithObject(object)
        }
        
        return true
    }
    
    // MARK: Private functions/properties
    
    internal let rbqFetchRequest: RBQFetchRequest
}