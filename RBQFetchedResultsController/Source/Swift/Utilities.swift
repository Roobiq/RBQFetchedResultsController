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

/**
Category on Realm that provides convenience methods similar to Realm class methods but include notifying RBQRealmNotificationManager
*/
extension Realm {

    // MARK: Helper Functions To Bridge Objective-C
    
    /**
    Convenience method to convert Configuration into RLMRealmConfiguration
    
    :nodoc:
    */
    internal class func toRLMConfiguration(_ configuration: Configuration) -> RLMRealmConfiguration {
        let rlmConfiguration = RLMRealmConfiguration()

        if let syncConfig = configuration.syncConfiguration {
            rlmConfiguration.syncConfiguration = RLMSyncConfiguration(user: syncConfig.user, realmURL: syncConfig.realmURL)
        }

        // Hack to get around issue with cache objects appearing in Realm
        // when building RBQFRC not as a framework
        let mirror = Mirror(reflecting: configuration)
        for child in mirror.children {
            if let customSchema = child.value as? RLMSchema, "customSchema" == child.label {
                // Filter out cache objects
                let schemaSubset = customSchema.objectSchema.filter { (objectSchema) -> Bool in
                    let cacheObjectNames = ["RBQControllerCacheObject",
                                            "RBQObjectCacheObject",
                                            "RBQSectionCacheObject"]

                    if cacheObjectNames.contains(objectSchema.objectName) {
                        return false
                    }

                    return true
                }

                rlmConfiguration.objectClasses = schemaSubset.map { $0.objectClass }
            }
        }

        if (configuration.fileURL != nil) {
            rlmConfiguration.fileURL = configuration.fileURL
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
