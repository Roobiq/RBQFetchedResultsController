//
//  ChangeLogger.swift
//  RBQFRCSwiftExample
//
//  Created by Adam Fish on 7/31/15.
//  Copyright (c) 2015 Adam Fish. All rights reserved.
//

import Realm
import RealmSwift

private let _defaultManager = ChangeLogger(rbqChangeLogger: RBQRealmChangeLogger.defaultLogger())

public class ChangeLogger {
    
    internal let rbqChangeLogger: RBQRealmChangeLogger
    
    internal init(rbqChangeLogger: RBQRealmChangeLogger) {
        self.rbqChangeLogger = rbqChangeLogger
    }
    
    public class func defaultLogger() -> ChangeLogger {
        return _defaultManager
    }
    
    // DOESN'T SUPPORT IN-MEMORY REALMS!!!
    public class func loggerForRealm(realm: Realm) -> ChangeLogger {
        return ChangeLogger(rbqChangeLogger: RBQRealmChangeLogger(forRealm: RLMRealm(path: realm.path)))
    }
    
    public func didAddObject(object: Object) {
        self.rbqChangeLogger.didAddObject(object)
    }
    
    public func didAddObjects<S: SequenceType where S.Generator.Element: Object>(objects: S) {
        for obj in objects {
            self.didAddObject(obj)
        }
    }
    
    public func willDeleteObject(object: Object) {
        self.rbqChangeLogger.willDeleteObject(object)
    }
    
    public func willDeleteObjects<S: SequenceType where S.Generator.Element: Object>(objects: S) {
        for obj in objects {
            self.willDeleteObject(obj)
        }
    }
    
    public func didChangeObject(object: Object) {
        self.rbqChangeLogger.didChangeObject(object)
    }
    
    public func didChangeObjects<S: SequenceType where S.Generator.Element: Object>(objects: S) {
        for obj in objects {
            self.didChangeObject(obj)
        }
    }
}