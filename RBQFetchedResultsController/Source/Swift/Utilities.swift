//
//  Utilities.swift
//  RBQFRCSwiftExample
//
//  Created by Adam Fish on 7/23/15.
//  Copyright (c) 2015 Adam Fish. All rights reserved.
//

import Foundation
import RealmSwift
import Realm
import Realm.Dynamic
import RealmUtilities

/**
This utility category provides convenience methods to retrieve the 
primary key and original class name for an Object.
*/
extension Object {
    
    // MARK: Functions
    
    /**
    Checks if an object is contained in a specific Realm
    
    :param: object Object with a primary key
    
    :returns: Bool indicating if the object is in a given Realm
    */
    public func isContainedIn(_ realm: Realm) -> Bool {
        
        if self.objectSchema.primaryKeyProperty == nil {
            return false
        }
        else if self.realm == nil {
            return false
        }
        
        let primaryKeyValue: Any? = Object.primaryKeyValue(forObject: self)
        
        let object = realm.dynamicObject(ofType: self.objectSchema.className, forPrimaryKey: primaryKeyValue!)
        
        if object != nil {
            return true
        }
        
        return false
    }
}
