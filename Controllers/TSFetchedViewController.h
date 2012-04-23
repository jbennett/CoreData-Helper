//
//  TSFetchedViewController.h
//  The System
//
//  Created by Jonathan Bennett on 2012-03-22.
//  Copyright (c) 2012 CCI Studios. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface TSFetchedViewController : UITableViewController <NSFetchedResultsControllerDelegate, UISearchDisplayDelegate>

@property (strong, nonatomic) NSString *entityName;
@property (strong, nonatomic) NSString *sortField;
@property (strong, nonatomic) NSString *searchField;
@property (strong, nonatomic) NSString *sectionKeyPath;
@property (strong, nonatomic) NSPredicate *filter;
@property (strong, nonatomic) NSString *cellIdentifier;
@property (strong, nonatomic) NSString *cache;
@property (assign, nonatomic) BOOL showIndex;

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) NSFetchedResultsController *searchFetchedResultsController;

- (NSFetchedResultsController *)fetchedResultsControllerForTableView:(UITableView *)tableView;
- (UITableView *)tableViewForFetchedResultsController:(NSFetchedResultsController *)controller;
- (void)filterContentForSearchString:(NSString *)search;

- (void)fetchedResultsController:(NSFetchedResultsController *)controller configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath;

@end
