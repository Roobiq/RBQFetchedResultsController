//
//  MainTableViewController.swift
//  RBQFRCSwiftExample
//
//  Created by Adam Fish on 7/31/15.
//  Copyright (c) 2015 Adam Fish. All rights reserved.
//

import Realm
import RealmSwift
import SafeRealmObject
import SwiftFetchedResultsController
import UIKit

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
    
    class func testObject(_ title: String, sortIndex: Int, inTable: Bool) -> TestObject {
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
        
        let _ = self.fetchedResultsController!.performFetch()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        
        return self.fetchedResultsController!.numberOfSections()
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return self.fetchedResultsController!.numberOfRowsForSectionIndex(section)
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return self.fetchedResultsController!.titleForHeaderInSection(section)
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "customCell", for: indexPath)
        
        // Configure the cell...
        
        let object = self.fetchedResultsController?.objectAtIndexPath(indexPath)
        
        cell.textLabel?.text = object?.title
        
        return cell
    }
    
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return NO if you do not want the specified item to be editable.
        return true
    }
    
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            self.deleteObjectAtIndexPath(indexPath)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }
    }
    
    // MARK: - Button Actions
    
    @IBAction func didPressInsertButton(_ sender: UIBarButtonItem) {
        self.insertObject()
    }
    @IBAction func didPressDeleteButton(_ sender: UIBarButtonItem) {
        
        let objectsInFirstSection = self.realm!.objects(TestObject.self).filter("%K == %@", "sectionName","First Section")
        
        try! self.realm!.write { () -> Void in
            self.realm!.delete(objectsInFirstSection)
        }
    }
    
    // MARK: - Private
    
    fileprivate func deleteObjectAtIndexPath(_ indexPath: IndexPath) {
        if let object = self.fetchedResultsController?.objectAtIndexPath(indexPath) {
            
            let realm = self.realm!
            
            try! realm.write({ () -> Void in
                realm.delete(object)
            })
        }
    }
    
    fileprivate func insertObject() {
        
        let realm = self.realm!
        
        let indexPathFirstRow = IndexPath(row: 0, section: 0)
        
        let object = self.fetchedResultsController?.objectAtIndexPath(indexPathFirstRow)
        
        if (object?.sortIndex)! > 0 {
            realm.beginWrite()
            
            let sortIndex = object!.sortIndex - 1
            
            let title = "Cell \(sortIndex)"
            
            var newObject = realm.object(ofType: TestObject.self, forPrimaryKey: "\(title)\(sortIndex)" as AnyObject)
            
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
            
            let indexPathFifthRow = IndexPath(row: 5, section: 0)
            let indexPathThirdRow = IndexPath(row: 3, section: 0)
            let indexPathSixthRow = IndexPath(row: 6, section: 0)
            let indexPathFirstRow = IndexPath(row: 0, section: 0)
            
            let firstObject = self.fetchedResultsController?.objectAtIndexPath(indexPathFirstRow)
            let thirdObject = self.fetchedResultsController?.objectAtIndexPath(indexPathThirdRow)
            let fifthObject = self.fetchedResultsController?.objectAtIndexPath(indexPathFifthRow)
            let sixthObject = self.fetchedResultsController?.objectAtIndexPath(indexPathSixthRow)
            let ninthObject = realm.objects(TestObject.self).filter("%K == %@", "title","Cell 9")
            
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
    
    func controllerWillChangeContent<T : Object>(_ controller: FetchedResultsController<T>) {
        self.tableView.beginUpdates()
    }
    
    public func controller<T : Object>(_ controller: FetchedResultsController<T>, didChangeObject anObject: SafeObject<T>, atIndexPath indexPath: IndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
        let tableView = self.tableView
        
        switch type {
            
        case .insert:
            tableView?.insertRows(at: [newIndexPath!], with: UITableViewRowAnimation.fade)
            
        case .delete:
            tableView?.deleteRows(at: [indexPath!], with: UITableViewRowAnimation.fade)
            
        case .update:
            tableView?.reloadRows(at: [indexPath!], with: UITableViewRowAnimation.fade)
            
        case .move:
            tableView?.deleteRows(at: [indexPath!], with: UITableViewRowAnimation.fade)
            tableView?.insertRows(at: [newIndexPath!], with: UITableViewRowAnimation.fade)
        }
    }
    
    func controllerDidChangeSection<T : Object>(_ controller: FetchedResultsController<T>, section: FetchResultsSectionInfo<T>, sectionIndex: UInt, changeType: NSFetchedResultsChangeType) {
        
        let tableView = self.tableView
        
        if changeType == NSFetchedResultsChangeType.insert {
            
            let indexSet = IndexSet(integer: Int(sectionIndex))
            
            tableView?.insertSections(indexSet, with: UITableViewRowAnimation.fade)
        }
        else if changeType == NSFetchedResultsChangeType.delete {
            
            let indexSet = IndexSet(integer: Int(sectionIndex))
            
            tableView?.deleteSections(indexSet, with: UITableViewRowAnimation.fade)
        }
    }
    
    func controllerDidChangeContent<T : Object>(_ controller: FetchedResultsController<T>) {
        self.tableView.endUpdates()
    }
}
