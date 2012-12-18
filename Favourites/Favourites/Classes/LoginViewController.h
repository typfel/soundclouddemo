//
//  LoginViewController.h
//  Favourites
//
//  Created by Jacob Persson on 2012-12-12.
//  Copyright (c) 2012 Jacob Persson. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "Account.h"

@class LoginViewController;

@protocol LoginViewControllerDelegate <NSObject>

- (void)loginViewControllerDidLogin:(LoginViewController *)sender;
- (void)loginViewControllerDidCancel:(LoginViewController *)sender;

@end

@interface LoginViewController : UIViewController

+ (BOOL)loggedIn;

@property (weak, nonatomic) id<LoginViewControllerDelegate> delegate;
@property (strong, nonatomic) Account *account;

@end
