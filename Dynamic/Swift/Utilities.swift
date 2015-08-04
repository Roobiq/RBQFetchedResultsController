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
*  This utility category provides convenience methods to retrieve the primary key and original
*  class name for an RLMObject.
*
*   DOESN'T SUPPORT IN-MEMORY REALMS!!!
*/
extension Object {
    
    /**
    *  Retrieve the primary key for a given RLMObject
    *
    *  @param object RLMObject with a primary key
    *
    *  @return Primary key value (NSInteger or NSString only)
    */
    public class func primaryKeyValueForObject(object: Object) -> AnyObject? {
        
        let primaryKeyProperty = object.objectSchema.primaryKeyProperty
        
        if (primaryKeyProperty != nil) {
            
            let value: AnyObject? = object.valueForKey(primaryKeyProperty!.name)
            
            return value
        }
        
        NSException(name: "RBQException", reason: "Object does not have a primary key", userInfo: nil).raise()
        
        return nil
    }
    
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
    *  Convenience method that accepts a RBQChangeNotificationBlock, which contains the current RLMObject as a parameter.
    *
    *  Edit the parameter object in the block and an automatic notification will be generated for RBQRealmChangeLogger
    *
    *  @param block Block contains the RLMObject used to call this method. Edit the RLMObject within the block.
    */
    public func changeWithNotification(changeBlock: (object: Object) -> Void) {
        
        if let realm = self.realm {
            
            changeBlock(object: self)
            
            ChangeLogger.loggerForRealm(realm).didChangeObject(self)
        }
    }
    
    /**
    *  Convenience method that accepts a RBQChangeNotificationBlock, which contains the current RLMObject as a parameter.
    *
    *  The block will be run within the required beginWriteTransaction and commitWriteTransaction calls automatically. Edit the parameter object in the block and an automatic notification will be generated for RBQRealmChangeLogger.
    *
    *  @param block Block contains the RLMObject used to call this method. Edit the RLMObject within the block.
    */
    public func changeWithNotificationInTransaction(changeBlock: (object: Object) -> Void) {
        
        if let realm = self.realm {
            
            realm.beginWrite()
            
            changeBlock(object: self)
            
            ChangeLogger.loggerForRealm(realm).didChangeObject(self)
            
            realm.commitWrite()
        }
    }
}

// DOESN'T SUPPORT IN-MEMORY REALMS!!!
extension Realm {
    
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
    
    public func addWithNotification<S: SequenceType where S.Generator.Element: Object>(objects: S, update: Bool) {
        for obj in objects {
            self.addWithNotification(obj, update: update)
        }
    }
    
    public func deleteWithNotification(object: Object) {
        ChangeLogger.loggerForRealm(self).willDeleteObject(object)
        
        self.delete(object)
    }
    
    public func deleteWithNotification<S: SequenceType where S.Generator.Element: Object>(objects: S) {
        for obj in objects {
            ChangeLogger.loggerForRealm(self).willDeleteObject(obj)
        }
        
        self.delete(objects)
    }
    
    public func deleteWithNotification<T: Object>(objects: List<T>) {
        for obj in objects {
            ChangeLogger.loggerForRealm(self).willDeleteObject(obj)
        }
        
        self.delete(objects)
    }
    
    public func deleteWithNotification<T: Object>(objects: Results<T>) {
        for obj in objects {
            ChangeLogger.loggerForRealm(self).willDeleteObject(obj)
        }
        
        self.delete(objects)
    }
}
