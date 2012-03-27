//
//  TSCoreDataHelper.h
//  The System
//
//  Created by Jonathan Bennett on 2012-03-17.
//  Copyright (c) 2012 CCI Studios. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

extern NSString *const DataManagerDidSaveNotification;
extern NSString *const DataManagerDidSaveFailedNotification;

@interface DataManager : NSObject

@property (nonatomic, readonly) NSManagedObjectModel *objectModel;
@property (nonatomic, readonly) NSManagedObjectContext *mainObjectContext;
@property (nonatomic, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;

+ (DataManager *)sharedInstance;
- (BOOL)save;
- (NSManagedObjectContext *)managedObjectContext;

- (NSMutableArray *)getObjectsForEntity:(NSString *)entityName withSortKey:(NSString *)sortKey andSortAscending:(BOOL)sortAscending;
- (NSMutableArray *)searchForEntity:(NSString *)entityName withPredicate:(NSPredicate *)predicate andSortKey:(NSString *)sortKey andSortAscending:(BOOL)sortAscending;
- (BOOL)deleteAllObjectsForEntity:(NSString *)entityName;
- (NSUInteger)countForEntity:(NSString *)entityName;
- (NSUInteger)countForEntity:(NSString *)entityName withPredicate:(NSPredicate *)predicate;

@end