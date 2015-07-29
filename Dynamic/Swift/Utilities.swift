//
//  Utilities.swift
//  RBQFRCSwiftExample
//
//  Created by Adam Fish on 7/23/15.
//  Copyright (c) 2015 Adam Fish. All rights reserved.
//

import Foundation
import RealmSwift

/**
*  This utility category provides convenience methods to retrieve the primary key and original
*  class name for an RLMObject.
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
}

//extension List {
//    public class func containsObject(object: Object) -> Bool {
//        
//        if self.indexOf(object) {
//            return true
//        }
//        
//        return false
//    }
//}
