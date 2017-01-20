//
//  ExampleTableViewController.swift
//  RBQFetchedResultsControllerSwiftExample
//
//  Created by Jeff on 4/2/15.
//  Copyright (c) 2015 Jeff. All rights reserved.
//

import UIKit
import Realm
import RBQFetchedResultsController


class ExampleTableViewController: UITableViewController, UITableViewDataSource, UITableViewDelegate, RBQFetchedResultsControllerDelegate {
    
    // MARK: variables
    let realm = RLMRealm.defaultRealm()
    var fetchedResultsController = RBQFetchedResultsController()
    
    func setUpFRC () {
        // Select and sort
        let predicate = NSPredicate(format: "inTable = YES")  // Can also use %i, %@
        let sortDescriptor = RLMSortDescriptor(property: "sortIndex", ascending: true)
        let sortDescriptorSection = RLMSortDescriptor(property: "sectionName", ascending: true)
        
        // Set up fetch
        let fetchRequest = RBQFetchRequest(entityName: "TestObject", inRealm: realm, predicate: predicate) // RBQFetchRequest(entityName: "InOut", inRealm: RLMRealm.defaultRealm(), predicate: predicate)
        fetchRequest.sortDescriptors = [sortDescriptor, sortDescriptorSection]  // can also be [primarySortDescriptor, secondarySortDescriptor]
        let fetchedResultsController = RBQFetchedResultsController(fetchRequest: fetchRequest, sectionNameKeyPath: "sectionName", cacheName: "testCache")
        
        fetchedResultsController.delegate = self
        let success = fetchedResultsController.performFetch()
        
        println("success: \(success), Total fetched: \(fetchedResultsController.fetchedObjects)")  //fetchedResultsController.fetchedObjects!.count
    }
    
    func initializeDB() {
        
        println ("realm.path: \(realm.path)")
    }
    
    
    
    
    // MARK: view
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        println ("realm.path: \(realm.path)")
        
        realm.beginWriteTransaction()
        realm.deleteAllObjects()
        
        for i in 0...1000 {
            let title = String("Cell \(i)")
//            let object = TestObject(title: title, sortIndex: i, inTable: true)
            let object = TestObject()
            object.title = title
            object.sortIndex = i
            object.inTable = true

            object.key = String(format: "\(object.title)\(object.sortIndex)")
            
            if i < 10 {
                object.sectionName = "First Section"
            } else {
                object.sectionName = "Second Section"
            }
            
            realm.addObject(object)
        }
        
        realm.commitWriteTransaction()
        
        // Set up fetch
        let predicate = NSPredicate(format: "inTable = YES")  // Can also use %i, %@
        let fetchRequest = RBQFetchRequest(entityName: "TestObject", inRealm: realm, predicate: predicate)
        
        let sortDescriptor = RLMSortDescriptor(property: "sortIndex", ascending: true)
        let sortDescriptorSection = RLMSortDescriptor(property: "sectionName", ascending: true)
        
        fetchRequest.sortDescriptors = [sortDescriptor, sortDescriptorSection]
        
        
        let fetchedResultsController = RBQFetchedResultsController(fetchRequest: fetchRequest, sectionNameKeyPath: "sectionName", cacheName: "testCache")
        
        fetchedResultsController.delegate = self
        let success = fetchedResultsController.performFetch()

    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    // MARK: Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        let numberOfSections = fetchedResultsController.numberOfSections()
        return numberOfSections
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let numberOfRowsForSectionIndex = fetchedResultsController.numberOfRowsForSectionIndex(section)
        return fetchedResultsController.numberOfRowsForSectionIndex(section)
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let title = fetchedResultsController.titleForHeaderInSection(section)
        return title
    }
    
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        var cell = tableView.dequeueReusableCellWithIdentifier("customCell", forIndexPath: indexPath) as UITableViewCell
        
        let objectForCell = fetchedResultsController.objectInRealm(realm, atIndexPath: indexPath) as TestObject
        cell.textLabel?.text = objectForCell.title
        return cell
    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if (editingStyle == UITableViewCellEditingStyle.Delete) {
            
            // Delete the row from the data source
            self.deleteObjectAtIndexPath(indexPath)
        } else if (editingStyle == UITableViewCellEditingStyle.Insert) {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
            self.insertObject()
        }
    }
    

    // MARK: Private
    func deleteObjectAtIndexPath(indexPath : NSIndexPath) {
        if let object = fetchedResultsController.objectInRealm(realm, atIndexPath: indexPath) as? TestObject {
            realm.beginWriteTransaction()
            realm.deleteObjectWithNotification(object)
            realm.commitWriteTransaction()
        }
    }
    
    func insertObject() {
        let indexPathFirstRow =  NSIndexPath(forRow: 0, inSection: 0)
        
        let object = fetchedResultsController.objectInRealm(realm, atIndexPath: indexPathFirstRow) as TestObject
        
        if object.sortIndex > 0 {
            realm.beginWriteTransaction()
            
            let sortIndex = object.sortIndex - 1;
            
            let title = NSString(format: "Cell %lu", CLong(sortIndex))
            
            if let newObject = RLMObject(inRealm: realm, forPrimaryKey: NSString(format: "%@%ld", title, CLong(sortIndex))) {
                newObject.changeWithNotification{ object in
                    let testObject = object as TestObject
                    testObject.inTable = true
                }
            } else {
//                let newObject = TestObject(title: title, sortIndex: sortIndex, inTable: true)
                let newObject = TestObject()
                newObject.title = title
                newObject.sortIndex = sortIndex
                newObject.inTable = true
                newObject.sectionName = "First Section"
                newObject.key = NSString(format: "%@%ld", title, CLong(sortIndex))
                realm.addObjectWithNotification(newObject)
            }
            realm.commitWriteTransaction()
        }
        

//    // Test Moves
//    else {
//    [realm beginWriteTransaction];
//    
//    NSIndexPath *indexPathFifthRow = [NSIndexPath indexPathForRow:5 inSection:0];
//    NSIndexPath *indexPathThirdRow = [NSIndexPath indexPathForRow:3 inSection:0];
//    NSIndexPath *indexPathSixthRow = [NSIndexPath indexPathForRow:6 inSection:0];
//    NSIndexPath *indexPathFirstRow = [NSIndexPath indexPathForRow:0 inSection:0];
//    
//    TestObject *firstObject = [self.fetchedResultsController objectInRealm:realm
//    atIndexPath:indexPathFirstRow];
//    TestObject *thirdObject = [self.fetchedResultsController objectInRealm:realm
//    atIndexPath:indexPathThirdRow];
//    TestObject *fifthObject = [self.fetchedResultsController objectInRealm:realm
//    atIndexPath:indexPathFifthRow];
//    TestObject *sixthObject = [self.fetchedResultsController objectInRealm:realm
//    atIndexPath:indexPathSixthRow];
//    RLMResults *ninthObject = [TestObject objectsInRealm:realm where:@"%K == %@",@"title",@"Cell 9"];
//    
//    [fifthObject changeWithNotification:^(RLMObject *object) {
//    TestObject *testObject = (TestObject *)object;
//    
//    testObject.sortIndex += 1;
//    }];
//    
//    [sixthObject changeWithNotification:^(RLMObject *object) {
//    TestObject *testObject = (TestObject *)object;
//    
//    testObject.sortIndex -= 1;
//    }];
//    
//    [firstObject changeWithNotification:^(RLMObject *object) {
//    TestObject *testObject = (TestObject *)object;
//    
//    testObject.inTable = NO;
//    }];
//    
//    [thirdObject changeWithNotification:^(RLMObject *object) {
//    TestObject *testObject = (TestObject *)object;
//    
//    testObject.title = @"Testing Move And Update";
//    }];
//    
//    if (ninthObject.firstObject) {
//    [ninthObject.firstObject changeWithNotification:^(RLMObject *object) {
//    TestObject *testObject = (TestObject *)object;
//    
//    if ([testObject.sectionName isEqualToString:@"First Section"]) {
//    testObject.sectionName = @"Second Section";
//    }
//    else {
//    testObject.sectionName = @"First Section";
//    }
//    }];
//    }
//    
//    //Test an inserted section that's not first
//    //        TestObject *extraObjectInSection = [TestObject testObjectWithTitle:@"Test Section" sortIndex:3 inTable:YES];
//    //        extraObjectInSection.sectionName = @"Middle Section";
//    //        [realm addObject:extraObjectInSection];
//    //
//    //        [[RBQRealmNotificationManager defaultManager] didAddObjects:@[extraObjectInSection]
//    //                                                  willDeleteObjects:nil
//    //                                                   didChangeObjects:@[NULL_IF_NIL(fifthObject),
//    //                                                                      NULL_IF_NIL(sixthObject),
//    //                                                                      NULL_IF_NIL(firstObject),
//    //                                                                      NULL_IF_NIL(thirdObject)]];
//    
//    [realm commitWriteTransaction];
//    }
//    }
    
   }
    
}