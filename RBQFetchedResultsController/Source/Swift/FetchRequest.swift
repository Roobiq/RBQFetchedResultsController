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
open class FetchRequest<T: Object> {
    
    // MARK: Initializers
    
    /**
    Constructor method to create a fetch request for a given entity name in a specific Realm.
    
    :param: realm      Realm in which the Object is persisted (if passing in-memory Realm, make sure to keep a strong reference elsewhere since fetch request only stores the path)
    :param predicate  NSPredicate that represents the search query or nil if all objects should be included
    
    :returns: A new instance of FetchRequest
    */
    public init(realm: Realm, predicate: NSPredicate?) {
        let entityName = T.className()
        
        self.realmConfiguration = realm.configuration
        
        let rlmConfiguration: RLMRealmConfiguration = ObjectiveCSupport.convert(object: realm.configuration)
        
        let rlmRealm = try! RLMRealm(configuration: rlmConfiguration)
        
        self.rbqFetchRequest = RBQFetchRequest(entityName: entityName, in: rlmRealm, predicate: predicate)
    }
    
    // MARK: Properties
    
    /// Object class name for the fetch request
    open var entityName: String {
        return self.rbqFetchRequest.entityName
    }
    
    /// The Realm in which the entity for the fetch request is persisted.
    open var realm: Realm {
        return try! Realm(configuration: self.realmConfiguration)
    }
    
    /// The configuration object used to create an instance of Realm for the fetch request
    open let realmConfiguration: Realm.Configuration
    
    /// Predicate supported by Realm
    ///
    /// http://realm.io/docs/cocoa/0.89.2/#querying-with-predicates
    open var predicate: NSPredicate? {
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
    open var sortDescriptors: [RealmSwift.SortDescriptor] {
        get {
            var sortDescriptors: [RealmSwift.SortDescriptor] = []
            
            if let rbqSortDescriptors = self.rbqFetchRequest.sortDescriptors {
                
                for rlmSortDesc in rbqSortDescriptors {
                    
                    sortDescriptors.append(SortDescriptor(property: rlmSortDesc.property, ascending: rlmSortDesc.ascending))
                }
            }
            
            return sortDescriptors
        }
        set {
            
            var rbqSortDescriptors = [RLMSortDescriptor]()
            
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
    open func fetchObjects() -> Results<T> {

//        var fetchResults = self.realm.objects(T)
        var fetchResults = self.realm.objects(T.self)

        // If we have a predicate use it
        
        if let predicate = self.predicate {
            fetchResults = fetchResults.filter(predicate)
        }
        
        // If we have sort descriptors then use them
        if (self.sortDescriptors.count > 0) {
            fetchResults = fetchResults.sorted(by: self.sortDescriptors)
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
    open func evaluateObject(_ object: T) -> Bool {
        
        if let predicate = self.predicate {
            return predicate.evaluate(with: object)
        }
        
        return true
    }
    
    // MARK: Private functions/properties
    
    internal let rbqFetchRequest: RBQFetchRequest
}
