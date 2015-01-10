//
//  ExampleTableViewController.m
//  RBQFetchedResultsControllerExample
//
//  Created by Adam Fish on 1/5/15.
//  Copyright (c) 2015 Roobiq. All rights reserved.
//

#import "ExampleTableViewController.h"

#import "RBQFetchedResultsController.h"
#import "TestObject.h"
#import "RBQRealmNotificationManager.h"

id NULL_IF_NIL(id x) {return x ? x : NSNull.null;}

@interface ExampleTableViewController () <RBQFetchedResultsControllerDelegate>

@property (strong, nonatomic) RBQFetchedResultsController *fetchedResultsController;

@end

@implementation ExampleTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    RLMRealm *realm = [RLMRealm defaultRealm];
    
    [realm beginWriteTransaction];
    
    [realm deleteAllObjects];
    
    for (NSUInteger i = 0; i < 1000; i++) {
        
        NSString *title = [NSString stringWithFormat:@"Cell %lu", (unsigned long)i];
        
        TestObject *object = [TestObject testObjectWithTitle:title sortIndex:i inTable:YES];
        
        if (i < 10) {
            object.sectionName = @"First Section";
        }
        else {
            object.sectionName = @"Second Section";
        }
        
        [realm addObject:object];
    }
    
    [realm commitWriteTransaction];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"inTable = YES"];
    
    RBQFetchRequest *fetchRequest = [RBQFetchRequest fetchRequestWithEntityName:@"TestObject"
                                                                        inRealm:realm
                                                                      predicate:predicate];
    
    RLMSortDescriptor *sortDescriptor = [RLMSortDescriptor sortDescriptorWithProperty:@"sortIndex"
                                                                            ascending:YES];
    
    RLMSortDescriptor *sortDescriptorSection = [RLMSortDescriptor sortDescriptorWithProperty:@"sectionName"
                                                                                   ascending:YES];
    
    fetchRequest.sortDescriptors = @[sortDescriptor, sortDescriptorSection];
    
    self.fetchedResultsController = [[RBQFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                           sectionNameKeyPath:@"sectionName" cacheName:@"testCache"];
    
    self.fetchedResultsController.delegate = self;
    
    [self.fetchedResultsController performFetch];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return [self.fetchedResultsController numberOfSections];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.fetchedResultsController numberOfRowsForSectionIndex:section];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [self.fetchedResultsController titleForHeaderInSection:section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"customCell" forIndexPath:indexPath];
    
    // Configure the cell...
    TestObject *objectForCell = [self.fetchedResultsController objectInRealm:[RLMRealm defaultRealm]
                                                                 atIndexPath:indexPath];
    
    cell.textLabel.text = objectForCell.title;
    
    
    return cell;
}

// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView
commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [self deleteObjectAtIndexPath:indexPath];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        [self insertObject];
    }
}

/*
 // Override to support rearranging the table view.
 - (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
 }
 */

// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}

#pragma mark - <RBQFetchedResultsControllerDelegate>

- (void)controllerWillChangeContent:(RBQFetchedResultsController *)controller
{
    NSLog(@"Beginning updates");
    [self.tableView beginUpdates];
}

- (void)controller:(RBQFetchedResultsController *)controller
   didChangeObject:(RBQSafeRealmObject *)anObject
       atIndexPath:(NSIndexPath *)indexPath
     forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{
    UITableView *tableView = self.tableView;
    
    switch(type) {
            
        case NSFetchedResultsChangeInsert:
        {
            NSLog(@"Inserting at path %@", newIndexPath);
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]
                             withRowAnimation:UITableViewRowAnimationFade];
            break;
        }
        case NSFetchedResultsChangeDelete:
        {
            NSLog(@"Deleting at path %ld", (long)indexPath.row);
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                             withRowAnimation:UITableViewRowAnimationFade];
            break;
        }
        case NSFetchedResultsChangeUpdate:
            NSLog(@"Updating at path %@", indexPath);
            if ([[tableView indexPathsForVisibleRows] containsObject:indexPath]) {
                [tableView reloadRowsAtIndexPaths:@[indexPath]
                                 withRowAnimation:UITableViewRowAnimationFade];
            }
            break;
            
        case NSFetchedResultsChangeMove:
            NSLog(@"Moving from path %@ to %@", indexPath, newIndexPath);
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                             withRowAnimation:UITableViewRowAnimationFade];
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]
                             withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controller:(RBQFetchedResultsController *)controller
  didChangeSection:(NSString *)sectionName
           atIndex:(NSUInteger)sectionIndex
     forChangeType:(NSFetchedResultsChangeType)type
{
    UITableView *tableView = self.tableView;
    
    if (type == NSFetchedResultsChangeInsert) {
        NSLog(@"Inserting section at %lu", (unsigned long)sectionIndex);
        NSIndexSet *insertedSection = [NSIndexSet indexSetWithIndex:sectionIndex];
        
        [tableView insertSections:insertedSection withRowAnimation:UITableViewRowAnimationFade];
    }
    else if (type == NSFetchedResultsChangeDelete) {
        NSLog(@"Deleting section at %lu", (unsigned long)sectionIndex);
        NSIndexSet *deletedSection = [NSIndexSet indexSetWithIndex:sectionIndex];
        
        [tableView deleteSections:deletedSection withRowAnimation:UITableViewRowAnimationFade];
    }
}

- (void)controllerDidChangeContent:(RBQFetchedResultsController *)controller
{
    NSLog(@"Ending updates");
    @try {
        [self.tableView endUpdates];
    }
    @catch (NSException *ex) {
        NSLog(@"RBQFecthResultsTVC caught exception updating table view: %@. Falling back to reload.", ex);
        [self.tableView reloadData];
    }
}

#pragma mark - UIBarButton Actions

- (IBAction)didClickDeleteButton:(UIBarButtonItem *)sender
{
    // Delete the object in the first row
//    NSIndexPath *firstObjectIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
//    [self deleteObjectAtIndexPath:firstObjectIndexPath];
    
    // Test deleting a section (comment out above to test)
    RLMResults *objectInFirstSection = [TestObject objectsWhere:@"%K == %@",@"sectionName",@"First Section"];

    [[RLMRealm defaultRealm] beginWriteTransaction];

    for (TestObject *object in objectInFirstSection) {
        [[RBQRealmNotificationManager defaultManager] willDeleteObject:object];

        [[RLMRealm defaultRealm] deleteObject:object];
    }

    [[RLMRealm defaultRealm] commitWriteTransaction];
}

- (IBAction)didClickInsertButton:(UIBarButtonItem *)sender
{
    [self insertObject];
}

#pragma mark - Private

- (void)deleteObjectAtIndexPath:(NSIndexPath *)indexPath
{
    RLMRealm *realm = [RLMRealm defaultRealm];
    
    TestObject *object = [self.fetchedResultsController objectInRealm:realm
                                                          atIndexPath:indexPath];
    if (!object) {
        return;
    }
    NSString *title = object.title;
    NSLog(@"Deleting object %@ at path %@", title, indexPath);
    
    [realm beginWriteTransaction];
    
    [[RBQRealmNotificationManager defaultManager] willDeleteObject:object];
    
    [realm deleteObject:object];
    
    [realm commitWriteTransaction];
    NSLog(@"Finished transaction with object %@", title);
}

- (void)insertObject
{
    RLMRealm *realm = [RLMRealm defaultRealm];
    
    NSIndexPath *indexPathFirstRow = [NSIndexPath indexPathForRow:0 inSection:0];
    
    TestObject *object = [self.fetchedResultsController objectInRealm:realm
                                                          atIndexPath:indexPathFirstRow];
    
    if (object.sortIndex > 0) {
        [realm beginWriteTransaction];
        
        NSInteger sortIndex = object.sortIndex - 1;
        
        NSString *title = [NSString stringWithFormat:@"Cell %lu", (unsigned long)sortIndex];
        
        
        TestObject *newObject = [TestObject objectInRealm:realm
                                            forPrimaryKey:[NSString stringWithFormat:@"%@%ld",title, (long)sortIndex]];
        
        if (!newObject) {
            newObject = [[TestObject alloc] init];
            newObject.title = title;
            newObject.sortIndex = sortIndex;
            newObject.sectionName = @"First Section";
            newObject.key = [NSString stringWithFormat:@"%@%ld",title, (long)sortIndex];
            newObject.inTable = YES;
            
            [realm addObject:newObject];
            NSLog(@"DID AN INSERT");
            [[RBQRealmNotificationManager defaultManager] didAddObject:newObject];
        }
        else {
            newObject.inTable = YES;
            NSLog(@"DID A CHANGE");
            [[RBQRealmNotificationManager defaultManager] didChangeObject:newObject];
        }
        
        
        
        [realm commitWriteTransaction];
    }
    // Test Moves
    else {
        [realm beginWriteTransaction];
        
        NSIndexPath *indexPathFifthRow = [NSIndexPath indexPathForRow:5 inSection:0];
        NSIndexPath *indexPathThirdRow = [NSIndexPath indexPathForRow:3 inSection:0];
        NSIndexPath *indexPathSixthRow = [NSIndexPath indexPathForRow:6 inSection:0];
        NSIndexPath *indexPathFirstRow = [NSIndexPath indexPathForRow:0 inSection:0];
        
        TestObject *firstObject = [self.fetchedResultsController objectInRealm:realm
                                                                   atIndexPath:indexPathFirstRow];
        TestObject *thirdObject = [self.fetchedResultsController objectInRealm:realm
                                                                   atIndexPath:indexPathThirdRow];
        TestObject *fifthObject = [self.fetchedResultsController objectInRealm:realm
                                                                   atIndexPath:indexPathFifthRow];
        TestObject *sixthObject = [self.fetchedResultsController objectInRealm:realm
                                                                   atIndexPath:indexPathSixthRow];
        
        [[RBQRealmNotificationManager defaultManager] didAddObjects:nil
                                                  willDeleteObjects:nil
                                                   didChangeObjects:@[NULL_IF_NIL(fifthObject),
                                                                      NULL_IF_NIL(sixthObject),
                                                                      NULL_IF_NIL(firstObject),
                                                                      NULL_IF_NIL(thirdObject)]];
        
        fifthObject.sortIndex += 1;
        sixthObject.sortIndex -= 1;
        firstObject.inTable = NO;
        thirdObject.title = @"Testing Move And Update";
        
        [realm commitWriteTransaction];
    }
}

@end
