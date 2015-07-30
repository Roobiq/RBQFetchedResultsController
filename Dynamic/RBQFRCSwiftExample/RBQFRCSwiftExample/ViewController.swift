//
//  ViewController.swift
//  RBQFRCSwiftExample
//
//  Created by Adam Fish on 7/23/15.
//  Copyright (c) 2015 Adam Fish. All rights reserved.
//

import UIKit
import Realm
import RealmSwift

class TestObject: Object {
    dynamic var stringCol = ""
    
    override class func primaryKey() -> String? {
        return "stringCol"
    }
}

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let anObject = TestObject()
        anObject.stringCol = "Adam"
        
        Realm().write { () -> Void in
            Realm().add(anObject, update: true)
        }
        
        if let object = Realm().objectForPrimaryKey(TestObject.self, key: "Adam") {
            
            let test = SafeObject(object: object)
            
            let rlmObject = test.object()
            
            
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

