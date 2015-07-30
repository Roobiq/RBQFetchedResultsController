//
//  SafeObject.swift
//  RBQFRCSwiftExample
//
//  Created by Adam Fish on 7/23/15.
//  Copyright (c) 2015 Adam Fish. All rights reserved.
//

import Realm
import RealmSwift

public class SafeObject<T: Object>: NSObject {
    
    let rbqSafeRealmObject: RBQSafeRealmObject
    
    internal init(rbqSafeRealmObject: RBQSafeRealmObject) {
        self.rbqSafeRealmObject = rbqSafeRealmObject
    }
    
    public init(object: T) {
        let rlmObject = unsafeBitCast(object, RLMObjectBase.self)
        
        self.rbqSafeRealmObject = RBQSafeRealmObject.safeObjectFromObject(rlmObject)
    }
    
    public func object() -> T {

        return unsafeBitCast(self.rbqSafeRealmObject.RLMObject(), T.self)
    }
    
}
