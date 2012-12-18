//
//  FeedViewController.h
//  Favourites
//
//  Created by Jacob Persson on 2012-12-12.
//  Copyright (c) 2012 Jacob Persson. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "LoginViewController.h"

@interface FeedViewController : UITableViewController <LoginViewControllerDelegate, NSFetchedResultsControllerDelegate>

@property (strong, nonatomic) IBOutlet UITableViewCell *trackTableViewCell;
@property (strong, nonatomic) IBOutlet UIView *tableFooterView;

- (void)presentLoginDialogAnimated:(BOOL)animated;

@end
