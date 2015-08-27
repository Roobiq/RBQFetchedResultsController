//
//  FetchRequest.swift
//  RBQFRCSwiftExample
//
//  Created by Adam Fish on 7/23/15.
//  Copyright (c) 2015 Adam Fish. All rights reserved.
//

import Realm
import RealmSwift

public class FetchRequest<T: Object> {
    internal let rbqFetchRequest: RBQFetchRequest
    
    public var entityName: String {
        return self.rbqFetchRequest.entityName
    }
    
    public var realm: Realm {
        
        return Realm(configuration: self.realmConfiguration, error: nil)!
    }
    
    internal let realmConfiguration: Realm.Configuration
    
    public var predicate: NSPredicate? {
        get {
            return self.rbqFetchRequest.predicate
        }
        set {
            self.rbqFetchRequest.predicate = predicate
        }
        
    }
    
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
    
    public init(realm: Realm, predicate: NSPredicate) {
        let entityName = T.className()
        
        self.realmConfiguration = realm.configuration
        
        let rlmConfiguration: RLMRealmConfiguration = Realm.toRLMConfiguration(realm.configuration)
        
        let rlmRealm = RLMRealm(configuration: rlmConfiguration, error: nil)
        
        self.rbqFetchRequest = RBQFetchRequest(entityName: entityName, inRealm: rlmRealm, predicate: predicate)
    }
    
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
    
    public func evaluateObject(object: T) -> Bool {
        
        if let predicate = self.predicate {
            return predicate.evaluateWithObject(object)
        }
        
        return true
    }
}