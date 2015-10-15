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
    public func isContainedIn(realm: Realm) -> Bool {
        
        if self.objectSchema.primaryKeyProperty == nil {
            return false
        }
        else if self.realm == nil {
            return false
        }
        
        let primaryKeyValue: AnyObject? = Object.primaryKeyValueForObject(self)
        
        let object = realm.dynamicObjectForPrimaryKey(self.objectSchema.className, key: primaryKeyValue!)
        
        if object != nil {
            return true
        }
        
        return false
    }
    
    /**
    Convenience method that accepts a block, which contains the current Object as a parameter.
    
    Edit the parameter object in the block and an automatic notification will be generated for ChangeLogger
    
    :param: block Block contains the Object used to call this method. Edit the Object within the block.
    */
    public func changeWithNotification(changeBlock: (object: Object) -> Void) {
        
        if let realm = self.realm {
            
            changeBlock(object: self)
            
            ChangeLogger.loggerForRealm(realm).didChangeObject(self)
        }
    }
    
    /**
    Convenience method that accepts a block, which contains the current Object as a parameter.
    
    The block will be run within the required beginWriteTransaction and commitWriteTransaction calls automatically. Edit the parameter object in the block and an automatic notification will be generated for ChangeLogger.
    
    :param: block Block contains the Object used to call this method. Edit the Object within the block.
    */
    public func changeWithNotificationInTransaction(changeBlock: (object: Object) -> Void) {
        
        if let realm = self.realm {
            
            realm.beginWrite()
            
            changeBlock(object: self)
            
            ChangeLogger.loggerForRealm(realm).didChangeObject(self)
            
            try! realm.commitWrite()
        }
    }
}

/**
Category on Realm that provides convenience methods similar to Realm class methods but include notifying RBQRealmNotificationManager
*/
extension Realm {
    
    // MARK: Functions
    
    /**
    Convenience method to add an object to the Realm and notify ChangeLogger
    
    :param: object Standalone Object to be persisted
    */
    public func addWithNotification(object: Object, update: Bool) {
        
        self.add(object, update: update)
        
        if update {
            
            if object.isContainedIn(self) {
                ChangeLogger.loggerForRealm(self).didChangeObject(object)
            }
            else {
                ChangeLogger.loggerForRealm(self).didAddObject(object)
            }
        }
        else {
            ChangeLogger.loggerForRealm(self).didAddObject(object)
        }
    }
    
    /**
    Convenience method to add a collection of Object to the Realm and notify ChangeLogger
    
    :param: objects A sequence which contains objects to be added to this Realm. This can be a `List<Object>`, `Results<Object>`, or any other enumerable `SequenceType` which generates `Object`.
    */
    public func addWithNotification<S: SequenceType where S.Generator.Element: Object>(objects: S, update: Bool) {
        for obj in objects {
            self.addWithNotification(obj, update: update)
        }
    }
    
    /**
    Convenience method to delete a Object from the Realm and notify ChangeLogger
    
    :param: object Object to delete from the Realm
    */
    public func deleteWithNotification(object: Object) {
        ChangeLogger.loggerForRealm(self).willDeleteObject(object)
        
        self.delete(object)
    }
    
    /**
    Convenience method to delete a collection of Objects from the Realm and notify ChangeLogger
    
    :param: objects The objects to be deleted. This can be a `List<Object>`, `Results<Object>`,
    or any other enumerable `SequenceType` which generates `Object`.
    */
    public func deleteWithNotification<S: SequenceType where S.Generator.Element: Object>(objects: S) {
        for obj in objects {
            ChangeLogger.loggerForRealm(self).willDeleteObject(obj)
        }
        
        self.delete(objects)
    }
    
    /**
    Convenience method to delete a collection of Objects from the Realm and notify ChangeLogger
    
    :param: objects The objects to be deleted. Must be `List<Object>`.
    
    :nodoc:
    */
    public func deleteWithNotification<T: Object>(objects: List<T>) {
        for obj in objects {
            ChangeLogger.loggerForRealm(self).willDeleteObject(obj)
        }
        
        self.delete(objects)
    }
    
    /**
    Convenience method to delete a collection of Objects from the Realm and notify ChangeLogger
    
    :param: objects The objects to be deleted. Must be `Results<Object>`.
    
    :nodoc:
    */
    public func deleteWithNotification<T: Object>(objects: Results<T>) {
        for obj in objects {
            ChangeLogger.loggerForRealm(self).willDeleteObject(obj)
        }
        
        self.delete(objects)
    }
    
    // MARK: Helper Functions To Bridge Objective-C
    
    /**
    Convenience method to convert Configuration into RLMRealmConfiguration
    
    :nodoc:
    */
    internal class func toRLMConfiguration(configuration: Configuration) -> RLMRealmConfiguration {
        let rlmConfiguration = RLMRealmConfiguration()
        
        if (configuration.path != nil) {
            rlmConfiguration.path = configuration.path
        }
        
        if (configuration.inMemoryIdentifier != nil) {
            rlmConfiguration.inMemoryIdentifier = configuration.inMemoryIdentifier
        }
        rlmConfiguration.encryptionKey = configuration.encryptionKey
        rlmConfiguration.readOnly = configuration.readOnly
        rlmConfiguration.schemaVersion = configuration.schemaVersion
        return rlmConfiguration
    }
}
