//
//  SafeObject.swift
//  RBQFRCSwiftExample
//
//  Created by Adam Fish on 7/23/15.
//  Copyright (c) 2015 Adam Fish. All rights reserved.
//

import Realm
import RealmSwift

public class SafeObject<T: Object>: Equatable {
    
    internal let rbqSafeRealmObject: RBQSafeRealmObject
    
    internal let realmConfiguration: Realm.Configuration
    
    internal init(rbqSafeRealmObject: RBQSafeRealmObject) {
        self.rbqSafeRealmObject = rbqSafeRealmObject
        self.realmConfiguration = Realm.toConfiguration(rbqSafeRealmObject.realmConfiguration)
    }
    
    public var className: String {
        return self.rbqSafeRealmObject.className
    }
    
    public var primaryKeyValue: AnyObject! {
        return self.rbqSafeRealmObject.primaryKeyValue
    }
    
    public var primaryKeyType: RLMPropertyType {
        return self.rbqSafeRealmObject.primaryKeyType
    }
    
    public var realm: Realm {
        return Realm(configuration: self.realmConfiguration, error: nil)!
    }
    
    public class func objectFromSafeObject(safeObject: SafeObject) -> T {
        return unsafeBitCast(safeObject.rbqSafeRealmObject.RLMObject(), T.self)
    }
    
    public init(object: T) {
        self.rbqSafeRealmObject = RBQSafeRealmObject.safeObjectFromObject(object)
        self.realmConfiguration = object.realm!.configuration
    }
    
    public func object() -> T {
        return unsafeBitCast(self.rbqSafeRealmObject.RLMObject(), T.self)
    }
}

// MARK: Equatable

/// Returns whether both objects are equal.
/// Objects are considered equal when they are both from the same Realm
/// and point to the same underlying object in the database.
public func == <T: Object>(lhs: SafeObject<T>, rhs: SafeObject<T>) -> Bool {
    
    if (lhs.primaryKeyType != rhs.primaryKeyType) {
        return false;
    }
    else if (lhs.primaryKeyType == RLMPropertyType.Int) {
        let lhsPrimaryKeyValue = lhs.primaryKeyValue as? Int
        let rhsPrimaryKeyValue = rhs.primaryKeyValue as? Int
        
        return lhsPrimaryKeyValue == rhsPrimaryKeyValue
    }
    else if (lhs.primaryKeyType == RLMPropertyType.String) {
        let lhsPrimaryKeyValue = lhs.primaryKeyValue as? String
        let rhsPrimaryKeyValue = rhs.primaryKeyValue as? String
        
        return lhsPrimaryKeyValue == rhsPrimaryKeyValue
        
    }
    
    return false
}
