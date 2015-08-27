//
//  ArrayTableViewController.m
//  RBQFRCDynamicExample
//
//  Created by Adam Fish on 8/26/15.
//  Copyright (c) 2015 Adam Fish. All rights reserved.
//

#import "ArrayTableViewController.h"
#import "TestObject.h"
#import "ParentObject.h"

#import "RBQFetchedResultsController.h"
#import "RBQRealmNotificationManager.h"
#import "RLMRealm+Notifications.h"
#import "RLMObject+Notifications.h"

#pragma mark - Constants

static NSString * const kRBQParentKey = @"RBQParentKey";

@interface ArrayTableViewController () <RBQFetchedResultsControllerDelegate>

@property (strong, nonatomic) RBQFetchedResultsController *fetchedResultsController;

@end

@implementation ArrayTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.leftBarButtonItems = [NSArray arrayWithObjects:self.navigationItem.leftBarButtonItem, self.navigationItem.rightBarButtonItem, nil];
    
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    self.tableView.backgroundColor = [UIColor colorWithWhite:0.93 alpha:1.0];
    
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    RLMRealm *realm = [RLMRealm defaultRealm];
    
    [realm beginWriteTransaction];
    
    [realm deleteAllObjects];
    
    ParentObject *parent = [[ParentObject alloc] init];
    parent.key = kRBQParentKey;
    
    [realm addObject:parent];
    
    for (NSUInteger i = 0; i < 10; i++) {
        
        NSString *title = [NSString stringWithFormat:@"Cell %lu", (unsigned long)i];
        
        TestObject *object = [TestObject testObjectWithTitle:title sortIndex:i inTable:YES];
        
        object.sectionName = @"First Section";
        
        [realm addObject:object];
        
        [parent.testObjects addObject:object];
    }
    
    [realm commitWriteTransaction];
    
    RBQFetchRequest *fetchRequest = [RBQArrayFetchRequest arrayFetchRequestForObject:parent
                                                                   withArrayProperty:@"testObjects"];
    
    self.fetchedResultsController = [[RBQFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                           sectionNameKeyPath:nil
                                                                                    cacheName:@"testCache"];
    
    self.fetchedResultsController.delegate = self;
    
    [self.fetchedResultsController performFetch];
}

- (void)didReceiveMemoryWarning {
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
    TestObject *objectForCell = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
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

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath
{
    RLMRealm *realm = [RLMRealm defaultRealm];
    
    [realm beginWriteTransaction];
    
    ParentObject *parent = [ParentObject objectForPrimaryKey:kRBQParentKey];
    
    TestObject *object = [self.fetchedResultsController objectAtIndexPath:sourceIndexPath];

    [parent.testObjects removeObjectAtIndex:[parent.testObjects indexOfObject:object]];
    
    [parent.testObjects insertObject:object atIndex:destinationIndexPath.row];
    
    [realm commitWriteTransaction];
}

#pragma mark - Private

- (void)deleteObjectAtIndexPath:(NSIndexPath *)indexPath
{
    typeof(self) __weak weakSelf = self;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        TestObject *object = [weakSelf.fetchedResultsController objectAtIndexPath:indexPath];
        if (!object) {
            return;
        }
        
        RLMRealm *realm = [RLMRealm defaultRealm];
        
        [realm beginWriteTransaction];
        
        [realm deleteObject:object];
        
        [realm commitWriteTransaction];
    });
}

- (void)insertObject
{
    RLMRealm *realm = [RLMRealm defaultRealm];
    
    NSIndexPath *indexPathFirstRow = [NSIndexPath indexPathForRow:0 inSection:0];
    
    TestObject *object = [self.fetchedResultsController objectAtIndexPath:indexPathFirstRow];
    
    if (object.sortIndex > 0 ||
        !object) {
        [realm beginWriteTransaction];
        
        NSInteger sortIndex = object ? object.sortIndex - 1 : 10;
        
        NSString *title = [NSString stringWithFormat:@"Cell %lu", (unsigned long)sortIndex];
        
        
        TestObject *newObject = [TestObject objectInRealm:realm
                                            forPrimaryKey:[NSString stringWithFormat:@"%@%ld",title, (long)sortIndex]];
        
        ParentObject *parent = [ParentObject objectInRealm:realm forPrimaryKey:kRBQParentKey];
        
        if (!newObject) {
            newObject = [[TestObject alloc] init];
            newObject.title = title;
            newObject.sortIndex = sortIndex;
            newObject.sectionName = @"First Section";
            newObject.key = [NSString stringWithFormat:@"%@%ld",title, (long)sortIndex];
            newObject.inTable = YES;
            
            [parent.testObjects insertObject:newObject atIndex:0];
        }
        else {
            newObject.inTable = YES;
        }
        
        [realm commitWriteTransaction];
    }
}

#pragma mark - UIBarButton Actions

- (IBAction)didClickDeleteButton:(UIBarButtonItem *)sender
{
    // Test deleting a section (comment out above to test)
    RLMResults *objectInFirstSection = [TestObject objectsWhere:@"%K == %@",@"sectionName",@"First Section"];
    
    RLMRealm *realm = [RLMRealm defaultRealm];
    
    [realm beginWriteTransaction];
    [realm deleteObjects:objectInFirstSection];
    [realm commitWriteTransaction];
}

- (IBAction)didClickInsertButton:(UIBarButtonItem *)sender
{
    [self insertObject];
}

#pragma mark - <RBQFetchedResultsControllerDelegate>

- (void)controllerWillChangeContent:(RBQFetchedResultsController *)controller
{
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
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]
                             withRowAnimation:UITableViewRowAnimationFade];
            break;
        }
        case NSFetchedResultsChangeDelete:
        {
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                             withRowAnimation:UITableViewRowAnimationFade];
            break;
        }
        case NSFetchedResultsChangeUpdate:
            if ([[tableView indexPathsForVisibleRows] containsObject:indexPath]) {
                [tableView reloadRowsAtIndexPaths:@[indexPath]
                                 withRowAnimation:UITableViewRowAnimationFade];
            }
            break;
            
        case NSFetchedResultsChangeMove:
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                             withRowAnimation:UITableViewRowAnimationFade];
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]
                             withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controller:(RBQFetchedResultsController *)controller
  didChangeSection:(RBQFetchedResultsSectionInfo *)sectionInfo
           atIndex:(NSUInteger)sectionIndex
     forChangeType:(NSFetchedResultsChangeType)type
{
    UITableView *tableView = self.tableView;
    
    if (type == NSFetchedResultsChangeInsert) {
        NSIndexSet *insertedSection = [NSIndexSet indexSetWithIndex:sectionIndex];
        
        [tableView insertSections:insertedSection withRowAnimation:UITableViewRowAnimationFade];
    }
    else if (type == NSFetchedResultsChangeDelete) {
        NSIndexSet *deletedSection = [NSIndexSet indexSetWithIndex:sectionIndex];
        
        [tableView deleteSections:deletedSection withRowAnimation:UITableViewRowAnimationFade];
    }
}

- (void)controllerDidChangeContent:(RBQFetchedResultsController *)controller
{
    [self.tableView endUpdates];
}

@end
