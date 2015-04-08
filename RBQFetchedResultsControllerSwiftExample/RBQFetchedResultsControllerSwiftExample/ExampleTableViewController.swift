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
        
        fetchedResultsController = RBQFetchedResultsController(fetchRequest: fetchRequest, sectionNameKeyPath: "sectionName", cacheName: "testCache")
        
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
        println("numberOfSections: \(numberOfSections)")
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
        
        if let objectForCell = fetchedResultsController.objectInRealm(realm, atIndexPath: indexPath) as? TestObject {
            cell.textLabel?.text = objectForCell.title
        }
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
    
    
    
    // MARK: <RBQFetchedResultsControllerDelegate>
    
    func controllerWillChangeContent(controller: RBQFetchedResultsController!) {
        NSLog("Beginning updates")
        self.tableView.beginUpdates()
    }
    
    func controller(controller: RBQFetchedResultsController!, didChangeObject anObject: RBQSafeRealmObject!, atIndexPath indexPath: NSIndexPath!, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath!) {
        let tableView = self.tableView
        
        switch(type) {
            
        case .Insert :
            if let newIndexPath = newIndexPath {
                NSLog("Inserting at path %@", newIndexPath)
                tableView.insertRowsAtIndexPaths([newIndexPath], withRowAnimation:UITableViewRowAnimation.Fade)
            }
            
        case .Delete :
            if let indexPath = indexPath {
                NSLog("Deleting at path %ld", indexPath.row)
                tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Fade)
            }
            
        case .Update :
            if let indexPath = indexPath {
                NSLog("Updating at path %@", indexPath)
                let visibleRows = tableView.indexPathsForVisibleRows() as [NSIndexPath]
                if contains(visibleRows, indexPath) {
                    tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Fade)
                }
            }
            
        case .Move :
            if let indexPath = indexPath {
                NSLog("Moving from path %@ to %@", indexPath, newIndexPath)
                if let newIndexPath = newIndexPath {
                    tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Fade)
                    tableView.insertRowsAtIndexPaths([newIndexPath], withRowAnimation: UITableViewRowAnimation.Fade)
                }
            }
        }
    }
    
    
    func controller(controller: RBQFetchedResultsController!, didChangeSection section: RBQFetchedResultsSectionInfo!, atIndex sectionIndex: UInt, forChangeType type: NSFetchedResultsChangeType) {
        let tableView = self.tableView
        
        switch(type) {
            
        case .Insert :
            NSLog("Inserting section at %lu", sectionIndex)
            
            let insertedSection = NSIndexSet(index: Int(sectionIndex))
            tableView.insertSections(insertedSection, withRowAnimation: UITableViewRowAnimation.Fade)
            
        case .Delete :
            NSLog("Deleting section at %lu", sectionIndex)
            
            let deletedSection = NSIndexSet(index: Int(sectionIndex))
            tableView.deleteSections(deletedSection, withRowAnimation: UITableViewRowAnimation.Fade)
            
        default :
            NSLog("Error, unhandled type in 'controller didChangeSection'")
            
        }
    }
    
    func controllerDidChangeContent(controller: RBQFetchedResultsController!) {
        NSLog("Ending updates")
        NSLog("Fetched %ld Items After Change", self.fetchedResultsController.fetchedObjects.count)
        
        tableView.endUpdates()
        //         try {
        //            [self.tableView endUpdates];
        //        }
        //        catch (NSException *ex) {
        //            NSLog(@"RBQFecthResultsTVC caught exception updating table view: %@. Falling back to reload.", ex);
        //
        //            [self.fetchedResultsController reset];
        //
        //            [self.tableView reloadData];
        //        }
        
    }
    
    
    @IBAction func didClickDeleteButton(sender: UIBarButtonItem) {
        
        // Delete the object in the first row
        //    NSIndexPath *firstObjectIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
        //    [self deleteObjectAtIndexPath:firstObjectIndexPath];
        
        NSLog("DID BEGIN DELETE");
        
        NSLog("Fetched %ld Items Before Delete", self.fetchedResultsController.fetchedObjects.count);
        
        // Test deleting a section (comment out above to test)
        let objectsInFirstSection = TestObject.objectsWhere("%K == %@","sectionName","First Section")
        
        realm.beginWriteTransaction()
        realm.deleteObjectsWithNotification([objectsInFirstSection])
        realm.commitWriteTransaction()
        
        NSLog("DID END DELETE");
    }
    
    
    @IBAction func didClickInsertButton(sender: AnyObject) {
        
        NSLog("DID BEGIN INSERT");
        NSLog("Fetched %ld Items Before Insert", self.fetchedResultsController.fetchedObjects.count);
        self.insertObject()
        NSLog("DID END INSERT");
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
            
            if let newObject = TestObject(inRealm: realm, forPrimaryKey: NSString(format: "%@%ld", title, CLong(sortIndex))) {
                newObject.changeWithNotification{ object in
                    let testObject = object as TestObject
                    testObject.inTable = true
                }
            } else {
                //                let newObject = TestObject(title: title, sortIndex: sortIndex, inTable: true)
                let newObject = TestObject()
                newObject.title = title
                newObject.sortIndex = sortIndex
                newObject.sectionName = "First Section"
                newObject.key = NSString(format: "%@%ld", title, CLong(sortIndex))
                newObject.inTable = true
                realm.addObjectWithNotification(newObject)
            }
            realm.commitWriteTransaction()
        }
            
            
            // Test Moves
        else {
            
            realm.beginWriteTransaction()
            
            let indexPathFifthRow = NSIndexPath(forRow: 5, inSection: 0)
            let indexPathThirdRow = NSIndexPath(forRow: 3, inSection: 0)
            let indexPathSixthRow = NSIndexPath(forRow: 6, inSection: 0)
            let indexPathFirstRow = NSIndexPath(forRow: 0, inSection: 0)
            
            if let firstObject = self.fetchedResultsController.objectInRealm(realm, atIndexPath: indexPathFirstRow) as? TestObject {
                firstObject.changeWithNotification{ object in
                    let testObject = object as TestObject
                    
                    testObject.inTable = false;
                }
            }
            
            if let thirdObject = self.fetchedResultsController.objectInRealm(realm, atIndexPath: indexPathThirdRow) as? TestObject {
                thirdObject.changeWithNotification{ object in
                    let testObject = object as TestObject
                    
                    testObject.title = "Testing Move And Update";
                }
            }
            if let fifthObject = self.fetchedResultsController.objectInRealm(realm, atIndexPath: indexPathFifthRow) as? TestObject {
                fifthObject.changeWithNotification{ object in
                    let testObject = object as TestObject
                    
                    testObject.sortIndex += 1;
                }
            }
            
            if let sixthObject = self.fetchedResultsController.objectInRealm(realm, atIndexPath: indexPathSixthRow) as? TestObject {
                sixthObject.changeWithNotification{ object in
                    let testObject = object as TestObject
                    
                    testObject.sortIndex -= 1;
                }
            }
            
            let ninthObject = TestObject.objectsInRealm(realm, "%K == %@", "title", "Cell 9")
            if let ninthO = ninthObject.firstObject() as? TestObject {
                ninthO.changeWithNotification{ object in
                    let testObject = object as TestObject
                    
                    if testObject.sectionName.isEqualToString("First Section") {
                        testObject.sectionName = "Second Section"
                    } else {
                        testObject.sectionName = "First Section"
                    }
                    
                    testObject.title = "Testing Move And Update";
                }
            }
            
            realm.commitWriteTransaction()
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
        }
        
    }
    
}
