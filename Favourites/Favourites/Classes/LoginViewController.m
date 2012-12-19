//
//  LoginViewController.m
//  Favourites
//
//  Created by Jacob Persson on 2012-12-12.
//  Copyright (c) 2012 Jacob Persson. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "LoginViewController.h"
#import "SCAPI.h"

#define TAG_LOGIN_BUTTON 1
#define TAG_LOGOUT_BUTTON 2
#define TAG_TOOLBAR 3
#define TAG_LOGGED_IN_MESSAGE_LABEL 4

#define keyPathUsername @"account.username"

@interface LoginViewController ()

@end

@implementation LoginViewController

+ (BOOL)loggedIn
{
    return [SCSoundCloud account] != nil;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self updateViewsOnAccountStateChanged];
    
    UIButton *loginButton  = (UIButton *)[self.view viewWithTag:TAG_LOGIN_BUTTON];
    
    UIImage *orangeButtonUpImage = [UIImage imageNamed:@"orange_button_up.png"];
    UIImage *orangeButtonDownImage = [UIImage imageNamed:@"orange_button_down.png"];
    
    [loginButton setBackgroundImage:[orangeButtonUpImage stretchableImageWithLeftCapWidth:20 topCapHeight:20] forState:UIControlStateNormal];
    [loginButton setBackgroundImage:[orangeButtonDownImage stretchableImageWithLeftCapWidth:20 topCapHeight:20] forState:UIControlStateHighlighted];
    
    UIButton *logoutButton  = (UIButton *)[self.view viewWithTag:TAG_LOGOUT_BUTTON];
    
    UIImage *redButtonUpImage = [UIImage imageNamed:@"red_button_up.png"];
    UIImage *redButtonDownImage = [UIImage imageNamed:@"red_button_down.png"];
    
    [logoutButton setBackgroundImage:[redButtonUpImage stretchableImageWithLeftCapWidth:20 topCapHeight:20] forState:UIControlStateNormal];
    [logoutButton setBackgroundImage:[redButtonDownImage stretchableImageWithLeftCapWidth:20 topCapHeight:20] forState:UIControlStateHighlighted];
    
    loginButton.layer.shadowOpacity = 1.0;
    loginButton.layer.shadowOffset = CGSizeMake(1.0, 1.0);
    loginButton.layer.shouldRasterize = YES;
    
    logoutButton.layer.shadowOpacity = 1.0;
    logoutButton.layer.shadowOffset = CGSizeMake(1.0, 1.0);
    logoutButton.layer.shouldRasterize = YES;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(SCSoundCloudAccountDidChangeNotification:)
                                                 name:SCSoundCloudAccountDidChangeNotification
                                               object:nil];
    
    [self addObserver:self forKeyPath:keyPathUsername options:NSKeyValueObservingOptionInitial context:nil];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [self removeObserver:self forKeyPath:keyPathUsername];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:keyPathUsername] && [LoginViewController loggedIn]) {
        UILabel *loggedInMessageLabel = (UILabel *)[self.view viewWithTag:TAG_LOGGED_IN_MESSAGE_LABEL];
        loggedInMessageLabel.text = [NSString stringWithFormat:@"logged in as %@", [object valueForKeyPath:keyPathUsername]];
    }
}

- (IBAction)login:(id)sender {
    [SCSoundCloud requestAccessWithPreparedAuthorizationURLHandler:^(NSURL *preparedURL) {
        [[UIApplication sharedApplication] openURL:preparedURL];
    }];
}

- (IBAction)logout:(id)sender {
    [SCSoundCloud removeAccess];
}

- (IBAction)cancel:(id)sender {
    if ([self.delegate respondsToSelector:@selector(loginViewControllerDidCancel:)]) {
        [self.delegate loginViewControllerDidCancel:self];
    }
}

- (void)updateViewsOnAccountStateChanged
{
    BOOL isConnectedWithAnAccount = [LoginViewController loggedIn];
    
    [self.view viewWithTag:TAG_LOGIN_BUTTON].hidden = isConnectedWithAnAccount;
    [self.view viewWithTag:TAG_LOGOUT_BUTTON].hidden = !isConnectedWithAnAccount;
    [self.view viewWithTag:TAG_TOOLBAR].hidden = !isConnectedWithAnAccount;
    
    if (!isConnectedWithAnAccount) {
       UILabel *loggedInMessageLabel = (UILabel *)[self.view viewWithTag:TAG_LOGGED_IN_MESSAGE_LABEL];
        loggedInMessageLabel.text = @"Connect with soundcloud to view your tracks.";
    }
}

#pragma mark - SCSoundCloud notifications

- (void)SCSoundCloudAccountDidChangeNotification:(NSNotification *)notification
{    
    [self updateViewsOnAccountStateChanged];
    
    if ([LoginViewController loggedIn] && [self.delegate respondsToSelector:@selector(loginViewControllerDidLogin:)]) {
        [self.delegate loginViewControllerDidLogin:self];
    }
}

@end