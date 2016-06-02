//
//  MainTableViewController.swift
//  RBQFRCSwiftExample
//
//  Created by Adam Fish on 7/31/15.
//  Copyright (c) 2015 Adam Fish. All rights reserved.
//

import UIKit
import Realm
import RealmSwift
import SwiftFetchedResultsController

// MARK: -

class TestObject: Object {
    dynamic var title = ""
    
    dynamic var sortIndex = 0
    
    dynamic var sectionName = ""
    
    dynamic var key = ""
    
    dynamic var inTable: Bool = false
    
    override class func primaryKey() -> String? {
        return "key"
    }
    
    class func testObject(title: String, sortIndex: Int, inTable: Bool) -> TestObject {
        let object = TestObject()
        
        object.title = title
        object.sortIndex = sortIndex
        object.inTable = inTable
        
        object.key = "\(title)\(sortIndex)"
        
        return object
    }
}

// MARK: -

class MainTableViewController: UITableViewController {
    
    var fetchedResultsController: FetchedResultsController<TestObject>?
    
    var realm: Realm?

    override func viewDidLoad() {
        super.viewDidLoad()

        let realm = try! Realm(configuration: Realm.Configuration(inMemoryIdentifier: "Test"))
        
        self.realm = realm
        
        realm.beginWrite()
        
        realm.deleteAll()
        
        for index in 1...1000 {
            
            let title = "Cell \(index)"
            
            let object = TestObject.testObject(title, sortIndex: index, inTable: true)
            
            if (index < 10) {
                object.sectionName = "First Section"
            }
            else {
                object.sectionName = "Second Section"
            }
            
            realm.add(object, update: false)
        }
        
        try! realm.commitWrite()
        
        let predicate = NSPredicate(format: "inTable = YES")
        
        let fetchRequest = FetchRequest<TestObject>(realm: realm, predicate: predicate)
        
        let sortDescriptor = SortDescriptor(property: "sortIndex", ascending: true)
        
        let sortDescriptorSection = SortDescriptor(property: "sectionName", ascending: true)
        
        fetchRequest.sortDescriptors = [sortDescriptorSection, sortDescriptor]
        
        self.fetchedResultsController = FetchedResultsController<TestObject>(fetchRequest: fetchRequest, sectionNameKeyPath: "sectionName", cacheName: "testCache")
        
        self.fetchedResultsController!.delegate = self
        
        self.fetchedResultsController!.performFetch()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {

        return self.fetchedResultsController!.numberOfSections()
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        return self.fetchedResultsController!.numberOfRowsForSectionIndex(section)
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return self.fetchedResultsController!.titleForHeaderInSection(section)
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("customCell", forIndexPath: indexPath) 

        // Configure the cell...
        
        let object = self.fetchedResultsController?.objectAtIndexPath(indexPath)

        cell.textLabel?.text = object?.title
        
        return cell
    }

    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the specified item to be editable.
        return true
    }

    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            self.deleteObjectAtIndexPath(indexPath)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    
    // MARK: - Button Actions
    
    @IBAction func didPressInsertButton(sender: UIBarButtonItem) {
        self.insertObject()
    }
    @IBAction func didPressDeleteButton(sender: UIBarButtonItem) {
        
        let objectsInFirstSection = self.realm!.objects(TestObject).filter("%K == %@", "sectionName","First Section")
        
        try! self.realm!.write { () -> Void in
            self.realm!.delete(objectsInFirstSection)
        }
    }
    
    // MARK: - Private
    
    private func deleteObjectAtIndexPath(indexPath: NSIndexPath) {
        if let object = self.fetchedResultsController?.objectAtIndexPath(indexPath) {
            
            let realm = self.realm!
            
            try! realm.write({ () -> Void in
                realm.delete(object)
            })
        }
    }
    
    private func insertObject() {
        
        let realm = self.realm!
            
        let indexPathFirstRow = NSIndexPath(forRow: 0, inSection: 0)
            
        let object = self.fetchedResultsController?.objectAtIndexPath(indexPathFirstRow)
            
        if object?.sortIndex > 0 {
            realm.beginWrite()
            
            let sortIndex = object!.sortIndex - 1
            
            let title = "Cell \(sortIndex)"
            
            var newObject = realm.objectForPrimaryKey(TestObject.self, key: "\(title)\(sortIndex)")
            
            if newObject == nil {
                newObject = TestObject()
                newObject!.title = title
                newObject!.sortIndex = sortIndex
                newObject!.sectionName = "First Section"
                newObject!.key = "\(title)\(sortIndex)"
                newObject!.inTable = true
                
                realm.add(newObject!, update: false)
            }
            else {
                newObject?.inTable = true
            }
            
            try! realm.commitWrite()
        }
        else { // Test Moves
            realm.beginWrite()
            
            let indexPathFifthRow = NSIndexPath(forRow: 5, inSection: 0)
            let indexPathThirdRow = NSIndexPath(forRow: 3, inSection: 0)
            let indexPathSixthRow = NSIndexPath(forRow: 6, inSection: 0)
            let indexPathFirstRow = NSIndexPath(forRow: 0, inSection: 0)
            
            let firstObject = self.fetchedResultsController?.objectAtIndexPath(indexPathFirstRow)
            let thirdObject = self.fetchedResultsController?.objectAtIndexPath(indexPathThirdRow)
            let fifthObject = self.fetchedResultsController?.objectAtIndexPath(indexPathFifthRow)
            let sixthObject = self.fetchedResultsController?.objectAtIndexPath(indexPathSixthRow)
            let ninthObject = realm.objects(TestObject).filter("%K == %@", "title","Cell 9")
            
            fifthObject?.sortIndex += 1
            
            sixthObject?.sortIndex -= 1
            
            firstObject?.inTable = false
            
            thirdObject?.title = "Testing Move And Update"
            
            if let testObject = ninthObject.first {
                
                if testObject.sectionName == "First Section" {
                    testObject.sectionName = "Second Section"
                }
                else {
                    testObject.sectionName = "First Section"
                }
            }
            
            try! realm.commitWrite()
        }
    }
}

// MARK: -

extension MainTableViewController: FetchedResultsControllerDelegate {
    func controllerWillChangeContent<T : Object>(controller: FetchedResultsController<T>) {
        self.tableView.beginUpdates()
    }
    
    func controllerDidChangeObject<T : Object>(controller: FetchedResultsController<T>, anObject: SafeObject<T>, indexPath: NSIndexPath?, changeType: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        
        let tableView = self.tableView
        
        switch changeType {
            
        case .Insert:
            
            tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: UITableViewRowAnimation.Fade)
            
        case .Delete:
            
            tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: UITableViewRowAnimation.Fade)
            
        case .Update:
            
            tableView.reloadRowsAtIndexPaths([indexPath!], withRowAnimation: UITableViewRowAnimation.Fade)
            
        case .Move:
            
            tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: UITableViewRowAnimation.Fade)
            
            tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: UITableViewRowAnimation.Fade)
        }
    }
    
    func controllerDidChangeSection<T : Object>(controller: FetchedResultsController<T>, section: FetchResultsSectionInfo<T>, sectionIndex: UInt, changeType: NSFetchedResultsChangeType) {
        
        let tableView = self.tableView
        
        if changeType == NSFetchedResultsChangeType.Insert {
            
            let indexSet = NSIndexSet(index: Int(sectionIndex))
            
            tableView.insertSections(indexSet, withRowAnimation: UITableViewRowAnimation.Fade)
        }
        else if changeType == NSFetchedResultsChangeType.Delete {
            
            let indexSet = NSIndexSet(index: Int(sectionIndex))
            
            tableView.deleteSections(indexSet, withRowAnimation: UITableViewRowAnimation.Fade)
        }
    }
    
    func controllerDidChangeContent<T : Object>(controller: FetchedResultsController<T>) {
        self.tableView.endUpdates()
    }

}
