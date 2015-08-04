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
        
        if let inMemoryId = self.rbqSafeRealmObject.inMemoryId {
            return Realm(inMemoryIdentifier: inMemoryId)
        }
        
        return Realm(path: self.rbqSafeRealmObject.realmPath)
    }
    
    public class func objectFromSafeObject(safeObject: SafeObject) -> T {
        return unsafeBitCast(safeObject.rbqSafeRealmObject.RLMObject(), T.self)
    }
    
    internal init(rbqSafeRealmObject: RBQSafeRealmObject) {
        self.rbqSafeRealmObject = rbqSafeRealmObject
    }
    
    public init(object: T) {
        self.rbqSafeRealmObject = RBQSafeRealmObject.safeObjectFromObject(object)
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
