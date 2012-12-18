//
//  AppDelegate.h
//  Favourites
//
//  Created by Jacob Persson on 2012-12-12.
//  Copyright (c) 2012 Jacob Persson. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SCSoundCloud;

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;

@end
