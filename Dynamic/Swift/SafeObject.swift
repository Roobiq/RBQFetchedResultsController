//
//  SafeObject.swift
//  RBQFRCSwiftExample
//
//  Created by Adam Fish on 7/23/15.
//  Copyright (c) 2015 Adam Fish. All rights reserved.
//

import Realm
import RealmSwift

/**
An RBQSafeRealmObject acts as a thread-safe representation of a Object.

:warning: SafeObjects can only be created from Objects that contain a primary key.
          Attempting to create a SafeObject without a primary key will result in an exception.
*/
public class SafeObject<T: Object>: Equatable {
    
    // MARK: Class Functions
    
    /**
    The configuration object used to create an instance of Realm for the fetch request
    */
    public class func objectFromSafeObject(safeObject: SafeObject) -> T {
        return unsafeBitCast(safeObject.rbqSafeRealmObject.RLMObject(), T.self)
    }
    
    // MARK: Initializer
    
    /**
    Constructor method to create an instance of SafeObject
    
    :param: object A Realm Object subclass
    
    :returns: A new instance of SafeObject
    */
    public init(object: T) {
        self.rbqSafeRealmObject = RBQSafeRealmObject.safeObjectFromObject(object)
        self.realmConfiguration = object.realm!.configuration
    }
    
    // MARK: Properties
    
    /**
    Original Object's class name
    */
    public var className: String {
        return self.rbqSafeRealmObject.className
    }
    
    /**
    Original Object's primary key value
    */
    public var primaryKeyValue: AnyObject! {
        return self.rbqSafeRealmObject.primaryKeyValue
    }
    
    /**
    Original Object's primary key property
    */
    public var primaryKeyType: RLMPropertyType {
        return self.rbqSafeRealmObject.primaryKeyType
    }
    
    /**
    The Realm in which this object is persisted. Generated on demand.
    */
    public var realm: Realm {
        return Realm(configuration: self.realmConfiguration, error: nil)!
    }
    
    // MARK: Functions
    
    /**
    Converts a SafeObject back into the Object
    
    :returns: A new instance of the Object
    */
    public func object() -> T {
        return unsafeBitCast(self.rbqSafeRealmObject.RLMObject(), T.self)
    }
    
    // MARK: Private Functions/Properties
    
    internal let rbqSafeRealmObject: RBQSafeRealmObject
    
    internal let realmConfiguration: Realm.Configuration
    
    internal init(rbqSafeRealmObject: RBQSafeRealmObject) {
        self.rbqSafeRealmObject = rbqSafeRealmObject
        self.realmConfiguration = Realm.toConfiguration(rbqSafeRealmObject.realmConfiguration)
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
