//
//  TSCoreDataHelper.m
//  The System
//
//  Created by Jonathan Bennett on 2012-03-17.
//  Copyright (c) 2012 CCI Studios. All rights reserved.
//

#import "DataManager.h"

NSString *const DataManagerDidSaveNotification = @"DataManagerDidSaveNotification";
NSString *const DataManagerDidSaveFailedNotification = @"DataManagerDidSaveFailedNotification";

@interface DataManager (Private)

- (NSString *)sharedDocumentsPath;

@end

@implementation DataManager
@synthesize objectModel = _objectModel;
@synthesize mainObjectContext = _mainObjectContext;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

NSString *const kDataManagerBundleName = nil;
NSString *const kDataManagerModelName = @"TheSystem";
NSString *const kDataManagerSQLiteName = @"TheSystem";

+ (DataManager *)sharedInstance
{
	static dispatch_once_t pred;
	static DataManager *sharedInstance = nil;
	
	dispatch_once(&pred, ^{ sharedInstance = [[self alloc] init]; });
	return sharedInstance;
}

- (NSManagedObjectModel *)objectModel
{
	if (_objectModel)
		return _objectModel;
	
	NSBundle *bundle = [NSBundle mainBundle];
	if (kDataManagerBundleName) {
		NSString *bundleName = [[NSBundle mainBundle] pathForResource:kDataManagerBundleName ofType:@"bundle"];
		bundle = [NSBundle bundleWithPath:bundleName];
	}
	
	NSString *modelPath = [bundle pathForResource:kDataManagerModelName ofType:@"momd"];
	_objectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:[NSURL fileURLWithPath:modelPath]];

	return _objectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
	if (_persistentStoreCoordinator)
		return _persistentStoreCoordinator;
	
	NSString *storePath = [[self sharedDocumentsPath] stringByAppendingFormat:kDataManagerSQLiteName];
	NSURL *storeURL = [NSURL fileURLWithPath:storePath];
	
	NSDictionary *option = [NSDictionary dictionaryWithObjectsAndKeys:
								[NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
								[NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption,
								nil];
	
	NSError *error = nil;
	_persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:self.objectModel];
	if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
												   configuration:nil
															 URL:storeURL
														 options:option 
														   error:&error]) {
		NSLog(@"Fatal error while creating persistent store: %@", error);
		abort();
	}
	
	return _persistentStoreCoordinator;
}

- (NSManagedObjectContext *)mainObjectContext
{
	if (_mainObjectContext)
		return _mainObjectContext;
	
	if (![NSThread isMainThread]) {
		[self performSelectorOnMainThread:@selector(mainObjectContext)
							   withObject:nil
							waitUntilDone:YES];
		return _mainObjectContext;
	}
	
	_mainObjectContext = [[NSManagedObjectContext alloc] init];
	[_mainObjectContext setPersistentStoreCoordinator:self.persistentStoreCoordinator];
	
	return _mainObjectContext;
}

- (NSManagedObjectContext *)managedObjectContext
{
	NSManagedObjectContext *ctx = [[NSManagedObjectContext alloc] init];
	[ctx setPersistentStoreCoordinator:self.persistentStoreCoordinator];
	
	return ctx;
}

- (BOOL)save
{
	if (![self.mainObjectContext hasChanges]) 
		return YES;
	
	NSError *error = nil;
	if (![self.mainObjectContext save:&error]) {
		NSLog(@"Error while saving: %@\n%@", [error localizedDescription], [error userInfo]);
		[[NSNotificationCenter defaultCenter] postNotificationName:DataManagerDidSaveFailedNotification
															object:error];
		return NO;
	}
	
	[[NSNotificationCenter defaultCenter] postNotificationName:DataManagerDidSaveNotification object:nil];
	return YES;
}

- (NSMutableArray *)searchForEntity:(NSString *)entityName withPredicate:(NSPredicate *)predicate andSortKey:(NSString *)sortKey andSortAscending:(BOOL)sortAscending
{
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:entityName inManagedObjectContext:self.mainObjectContext];
	[request setEntity:entity];
	
	if (request != nil) {
		[request setPredicate:predicate];
	}
	
	if (sortKey != nil) {
		NSSortDescriptor *sortdescriptor = [[NSSortDescriptor alloc] initWithKey:sortKey ascending:sortAscending];
		[request setSortDescriptors:[NSArray arrayWithObject:sortdescriptor]];
	}
	
	NSError *error = nil;
	NSMutableArray *mutableFetchResults = [[self.mainObjectContext executeFetchRequest:request error:&error] mutableCopy];
	
	if (mutableFetchResults == nil)
		NSLog(@"Couldn't get object for entity %@", entityName);
	
	return mutableFetchResults;
}

- (NSMutableArray *)getObjectsForEntity:(NSString *)entityName withSortKey:(NSString *)sortKey andSortAscending:(BOOL)sortAscending
{
	return [self searchForEntity:entityName withPredicate:nil andSortKey:sortKey andSortAscending:sortAscending];
}

- (NSUInteger)countForEntity:(NSString *)entityName withPredicate:(NSPredicate *)predicate
{
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:entityName inManagedObjectContext:self.mainObjectContext];
	[request setEntity:entity];
	[request setIncludesSubentities:NO];
	
	if (predicate != nil) {
		[request setPredicate:predicate];
	}
	
	NSError *error = nil;
	NSUInteger count = [self.mainObjectContext countForFetchRequest:request error:&error];
	
	if (count == NSNotFound)
		NSLog(@"Couldn't get count for entity %@", entity);
	
	return count;
}

- (NSUInteger)countForEntity:(NSString *)entityName
{
	return [self countForEntity:entityName withPredicate:nil];
}

- (BOOL)deleteAllObjectsForEntity:(NSString *)entityName
{
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:entityName inManagedObjectContext:self.mainObjectContext];
	[request setEntity:entity];
	[request setIncludesPropertyValues:NO];
	
	NSError *error = nil;
	NSArray *fetchResults = [self.mainObjectContext executeFetchRequest:request error:&error];
	
	if (fetchResults != nil) {
		for (NSManagedObject *manObj in fetchResults) {
			[self.mainObjectContext deleteObject:manObj];
		}
	} else {
		NSLog(@"Couldn't delete objects for entity %@", entityName);
	}
	
	return YES;
}

- (NSString *)sharedDocumentsPath
{
	static NSString *SharedDocumentsPath = nil;
	if (SharedDocumentsPath)
		return SharedDocumentsPath;
	
	NSString *libraryPath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
	SharedDocumentsPath = [libraryPath stringByAppendingPathComponent:@"Database"];
	
	NSFileManager *manager = [NSFileManager defaultManager];
	BOOL isDirectory;
	if (![manager fileExistsAtPath:SharedDocumentsPath isDirectory:&isDirectory] || !isDirectory) {
		NSError *error;
		NSDictionary *attr = [NSDictionary dictionaryWithObject:NSFileProtectionComplete
														 forKey:NSFileProtectionKey];
		
		NSLog(@"%@", SharedDocumentsPath);
		
		[manager createDirectoryAtPath:SharedDocumentsPath
		   withIntermediateDirectories:YES
						   attributes:attr
								error:&error];
		
		if (error) {
			NSLog(@"Error creating directory path: %@", [error localizedDescription]);
		}
	}
	
	return SharedDocumentsPath;
}

@end
