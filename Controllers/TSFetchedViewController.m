//
//  TSFetchedViewController.m
//  The System
//
//  Created by Jonathan Bennett on 2012-03-22.
//  Copyright (c) 2012 CCI Studios. All rights reserved.
//

#import "TSFetchedViewController.h"
#import "DataManager.h"

@interface TSFetchedViewController ()
- (NSFetchedResultsController *)createFetchedResultsControllerWithPredicate:(NSPredicate *)predicate;
@end

@implementation TSFetchedViewController
@synthesize fetchedResultsController = _fetchedResultsController;

- (id)initWithCoder:(NSCoder *)aDecoder
{
	if (self = [super initWithCoder:aDecoder]) {
		self.entityName = nil;
		self.sortField = nil;
		self.searchField = nil;
		self.sectionKeyPath = nil;
		self.filter = nil;
		self.cellIdentifier = nil;
		self.cache = @"Root";
		self.showIndex = YES;
	}
	
	return self;
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	NSError *error = nil;
	if (![self.fetchedResultsController performFetch:&error]) {
		NSLog(@"Fail to fetch %@", self.entityName);
	}
}

- (void)viewDidUnload
{
	self.fetchedResultsController = nil;
}

#pragma mark -
#pragma mark Setters
- (NSFetchedResultsController *)fetchedResultsController
{
	if (_fetchedResultsController)
		return _fetchedResultsController;
	
	_fetchedResultsController = [self createFetchedResultsControllerWithPredicate:self.filter];
	return _fetchedResultsController;
}

- (NSFetchedResultsController *)searchFetchedResultsController
{
	if (_searchFetchedResultsController)
		return _searchFetchedResultsController;
	
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%@ contains[cd] %@", self.searchField, self.searchDisplayController.searchBar.text];
	_searchFetchedResultsController = [self createFetchedResultsControllerWithPredicate:predicate];
	return _searchFetchedResultsController;
}

#pragma mark - 
#pragma mark Helpers
- (NSFetchedResultsController *)fetchedResultsControllerForTableView:(UITableView *)tableView
{
	return tableView == self.tableView ? self.fetchedResultsController : self.searchFetchedResultsController;
}

- (UITableView *)tableViewForFetchedResultsController:(NSFetchedResultsController *)controller
{
	return controller == self.fetchedResultsController ? self.tableView : self.searchDisplayController.searchResultsTableView;
}

#pragma mark - 
#pragma mark NSFetchedResultsController
- (NSFetchedResultsController *)createFetchedResultsControllerWithPredicate:(NSPredicate *)predicate
{
	DataManager *dm = [DataManager sharedInstance];
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:self.entityName inManagedObjectContext:dm.mainObjectContext];
	fetchRequest.entity = entity;
	[fetchRequest setSortDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:self.sortField ascending:YES]]];
	[fetchRequest setFetchBatchSize:20];
	[fetchRequest setPredicate:predicate];
	
	NSFetchedResultsController *fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
																							   managedObjectContext:dm.mainObjectContext
																								 sectionNameKeyPath:self.sectionKeyPath
																										  cacheName:self.cache];
	fetchedResultsController.delegate = self;
	[NSFetchedResultsController deleteCacheWithName:self.cache];
	
	return fetchedResultsController;
}

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
	[[self tableViewForFetchedResultsController:controller] beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath
{
	UITableView *tableView = [self tableViewForFetchedResultsController:controller];
	
	switch (type) {
		case NSFetchedResultsChangeInsert:
			[tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
			break;
		case NSFetchedResultsChangeDelete:
			[tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
			break;
		case NSFetchedResultsChangeUpdate:
			[self fetchedResultsController:controller configureCell:[tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
			break;
		case NSFetchedResultsChangeMove:
			[tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
			[tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
			break;
	}
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id<NSFetchedResultsSectionInfo>)sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
{
	UITableView *tableView = [self tableViewForFetchedResultsController:controller];
	
	switch (type) {
		case NSFetchedResultsChangeInsert:
			[tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
			break;
		case NSFetchedResultsChangeDelete:
			[tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
			break;
	}
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
	[[self tableViewForFetchedResultsController:controller] endUpdates];
}

#pragma mark -
#pragma mark UITableView Delegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return [[[self fetchedResultsControllerForTableView:tableView] sections] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	id<NSFetchedResultsSectionInfo> sectionInfo = [[[self fetchedResultsControllerForTableView:tableView] sections] objectAtIndex:section];
	return [sectionInfo numberOfObjects];
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
	if (!self.showIndex || !self.sectionKeyPath)
		return nil;
	
	return [[self fetchedResultsControllerForTableView:tableView] sectionIndexTitles];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	id<NSFetchedResultsSectionInfo> sectionInfo = [[[self fetchedResultsControllerForTableView:tableView] sections] objectAtIndex:section];
	return [sectionInfo name];
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index
{
	return [[self fetchedResultsControllerForTableView:tableView] sectionForSectionIndexTitle:title atIndex:index];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:self.cellIdentifier];
	if (cell == nil) {
		cell = [self.tableView dequeueReusableCellWithIdentifier:self.cellIdentifier];
	}
	
	[self fetchedResultsController:[self fetchedResultsControllerForTableView:tableView] configureCell:cell atIndexPath:indexPath];
	return cell;
}

- (void)fetchedResultsController:(NSFetchedResultsController *)fetchedResultsController configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
}

#pragma mark -
#pragma mark Search Delegate
- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
	[self filterContentForSearchString:searchString];
	return YES;
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchScope:(NSInteger)searchOption
{
	return YES;
}

- (void)searchDisplayController:(UISearchDisplayController *)controller willUnloadSearchResultsTableView:(UITableView *)tableView
{
	self.searchFetchedResultsController.delegate = nil;
	self.searchFetchedResultsController = nil;
}

- (void)filterContentForSearchString:(NSString *)search
{
	if (search && search.length) {
		[NSFetchedResultsController deleteCacheWithName:self.cache];
		NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K contains[cd] %@", self.searchField, search];
		[self.searchFetchedResultsController.fetchRequest setPredicate:predicate];
	}
	
	NSError *error = nil;
	if (![self.searchFetchedResultsController performFetch:&error]) {
		NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
	}
}

@end
