//
//  TestObject.swift
//  TimeHenPersonal
//
//  Created by Jeff on 4/1/15.
//  Copyright (c) 2015 Jeff. All rights reserved.
//


import Realm

class TestObject: RLMObject {
    dynamic var title : NSString = "Default Title"
    dynamic var sortIndex : NSInteger = 0
    dynamic var sectionName : NSString = "Section 1"
    dynamic var key : NSString = "Section 1"
    dynamic var inTable : Bool = true
    
    override class func primaryKey() -> String {
        return "key"
    }
    
//    init(title: NSString, sortIndex: NSInteger, inTable: Bool) {
//        super.init()
//        self.sortIndex = sortIndex
//        self.title = title
//        self.key = NSString(format: "%@%ld", title, CLong(sortIndex))
//        self.inTable = inTable
//    }
}
