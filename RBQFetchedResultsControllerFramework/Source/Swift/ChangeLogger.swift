//
//  ChangeLogger.swift
//  RBQFRCSwiftExample
//
//  Created by Adam Fish on 7/31/15.
//  Copyright (c) 2015 Adam Fish. All rights reserved.
//

import Realm
import RealmSwift

// Private Singleton
private let _defaultManager = ChangeLogger(rbqChangeLogger: RBQRealmChangeLogger.defaultLogger())

/**
This class is used to track changes to a given Realm. Since Realm doesn't support automatic change tracking, this class allows the developer to log object changes, which will be passed along to the RBQRealmNotificationManager who in turn broadcasts it to any listeners

Since Objects are not thread-safe, when an object is logged to the manager, it is internally transformed into a SafeObject that is thread-safe and this will then be passed to any listeners once the Realm being monitored updates.

:warning: Only Objects with primary keys can be logged because the primary key is required to create a SafeObject.
*/
public class ChangeLogger {
    
    // MARK: Class Functions
    
    /**
    Creates or retrieves the logger instance for the default Realm on the current thread
    
    :returns: Instance of ChangeLogger
    */
    public class func defaultLogger() -> ChangeLogger {
        return _defaultManager
    }
    
    /**
    Creates or retrieves the logger instance for a specific Realm on the current thread
    
    :param: realm A Realm instance
    
    :returns: Instance of ChangeLogger
    */
    public class func loggerForRealm(realm: Realm) -> ChangeLogger {
        
        let rlmConfiguration: RLMRealmConfiguration = Realm.toRLMConfiguration(realm.configuration)
        
        let rlmRealm = try! RLMRealm(configuration: rlmConfiguration)
        
        return ChangeLogger(rbqChangeLogger: RBQRealmChangeLogger(forRealm: rlmRealm))
    }
    
    // MARK: Functions
    
    /**
    Register an addition for a given Object
    
    :warning: Can be called before or after the addition to Realm

    :param: addedObject Added Object
    */
    public func didAddObject(object: Object) {
        self.rbqChangeLogger.didAddObject(object)
    }
    
    /**
    *  Register a collection of Object additions
    
    :warning: Can be called before or after the additions to Realm
    
    :param: addedObjects A sequence which contains objects that were added to this Realm. This can be a `List<Object>`, `Results<Object>`, or any other enumerable `SequenceType` which generates `Object`.
    */
    public func didAddObjects<S: SequenceType where S.Generator.Element: Object>(objects: S) {
        for obj in objects {
            self.didAddObject(obj)
        }
    }
    
    /**
    *  Register a delete for a given Object
    
    :warning: Must be called before the delete in Realm (since the Object will then be invalidated).
    
    :param: deletedObject To be deleted Object
    */
    public func willDeleteObject(object: Object) {
        self.rbqChangeLogger.willDeleteObject(object)
    }
    
    /**
    *  Register a collection of Object deletes
    
    :warning: Must be called before the delete in Realm (since the Object will then be invalidated).
    
    :param: deletedObjects A sequence which contains objects that will be deleted. This can be a `List<Object>`, `Results<Object>`, or any other enumerable `SequenceType` which generates `Object`.
    */
    public func willDeleteObjects<S: SequenceType where S.Generator.Element: Object>(objects: S) {
        for obj in objects {
            self.willDeleteObject(obj)
        }
    }
    
    /**
    *  Register a change for a given Object
    
    :warning: Can be called before or after change to Realm
    
    :param: changedObject Changed Object
    */
    public func didChangeObject(object: Object) {
        self.rbqChangeLogger.didChangeObject(object)
    }
    
    /**
    *  Register a collection of Object changes
    
    :warning: Can be called before or after change to Realm
    
    :param: changedObjects A sequence which contains objects that were changed. This can be a `List<Object>`, `Results<Object>`, or any other enumerable `SequenceType` which generates `Object`.
    */
    public func didChangeObjects<S: SequenceType where S.Generator.Element: Object>(objects: S) {
        for obj in objects {
            self.didChangeObject(obj)
        }
    }
    
    // MARK: Private Functions/Properties
    
    internal let rbqChangeLogger: RBQRealmChangeLogger
    
    internal init(rbqChangeLogger: RBQRealmChangeLogger) {
        self.rbqChangeLogger = rbqChangeLogger
    }
}