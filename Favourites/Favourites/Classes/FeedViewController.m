//
//  FeedViewController.m
//  Favourites
//
//  Created by Jacob Persson on 2012-12-12.
//  Copyright (c) 2012 Jacob Persson. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "SCAPI.h"
#import "UIImageView+WebCache.h"

#import "FeedViewController.h"
#import "LoginViewController.h"
#import "FeedController.h"
#import "Track.h"
#import "AppDelegate.h"
#import "WaveformView.h"

#define TAG_TRACK_TITLE_LABEL 5
#define TAG_TRACK_ARTIST_LABEL 1
#define TAG_TRACK_DATE_LABEL 2
#define TAG_TRACK_ARTWORK_IMAGE_VIEW 3
#define TAG_TRACK_WAVEFORM_IMAGE_VIEW 4

@interface FeedViewController () {
    NSDateFormatter *dateFormatter;
    FeedController *feedController;
    NSFetchedResultsController *fetchedResultsController;
    BOOL isCurrentlyloadingMoreResults;
}

@end

@implementation FeedViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        isCurrentlyloadingMoreResults = NO;
        feedController = [[FeedController alloc] init];
        
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"dd MMM yyyy"];
        
        AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        NSManagedObjectContext *context = [appDelegate managedObjectContext];
        
        fetchedResultsController = [[NSFetchedResultsController alloc]
                                    initWithFetchRequest:[self createFetchRequestForTracksOrderedByDateInContext:context]
                                    managedObjectContext:context
                                    sectionNameKeyPath:nil
                                    cacheName:nil];
        
        fetchedResultsController.delegate = self;
        
        NSError *error;
        BOOL success = [fetchedResultsController performFetch:&error];
        
        if (!success) {
            NSLog(@"Fetch tracks failed with error: %@", error);
        }
        
        if (!feedController.account && [SCSoundCloud account]) {
            // A valid OAuth token was found so we reload the account
            [self reloadAccount];
        }
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    if ([self hasSupportForPullToRefresh]) {
        UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
        [refreshControl addTarget:self action:@selector(refreshFeed) forControlEvents:UIControlEventValueChanged];
        self.refreshControl = refreshControl;
    }
        
    [[NSBundle mainBundle] loadNibNamed:@"FeedTableFooterView" owner:self options:nil];
    
    UIBarButtonItem *accountButton = [[UIBarButtonItem alloc] initWithTitle:@"Account"
                                                                      style:UIBarButtonItemStyleBordered
                                                                     target:self
                                                                     action:@selector(presentLoginDialog)];
    
    UIBarButtonItem *refreshButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh
                                                                                   target:self
                                                                                   action:@selector(refreshFeed)];
        
    self.navigationItem.leftBarButtonItem = accountButton;
    self.navigationItem.rightBarButtonItem = refreshButton;
    self.navigationItem.title = @"\u2601 Tracks";
    
    self.navigationController.navigationBar.tintColor = [UIColor colorWithRed:0.980 green:0.294 blue:0.0 alpha:1.0];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSFetchRequest *)createFetchRequestForTracksOrderedByDateInContext:(NSManagedObjectContext *)context
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:[NSEntityDescription entityForName:@"Track" inManagedObjectContext:context]];
    
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"account = %@", feedController.account];
    
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"createdAt" ascending:NO];
    NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    return fetchRequest;
}

- (BOOL)hasSupportForPullToRefresh
{
    return NSClassFromString(@"UIRefreshControl") && [self respondsToSelector:@selector(refreshControl)];
}


- (void)resetFetchRequest
{
    fetchedResultsController.fetchRequest.predicate = [NSPredicate predicateWithFormat:@"account = %@", feedController.account];
    
    NSError *error;
    BOOL success = [fetchedResultsController performFetch:&error];
    
    if (!success) {
        NSLog(@"Fetch tracks failed with error: %@", error);
    }
    
    [self.tableView reloadData];
}

- (void)presentLoginDialog
{
    [self presentLoginDialogAnimated:YES];
}

- (void)presentLoginDialogAnimated:(BOOL)animated
{
    LoginViewController *loginViewController = [[LoginViewController alloc] initWithNibName:@"LoginViewController" bundle:nil];
    loginViewController.account = feedController.account;
    loginViewController.delegate = self;
    loginViewController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    
    [self presentModalViewController:loginViewController animated:animated];
}

- (void)hideTableFooter
{
    self.tableView.tableFooterView = nil;
}

- (void)showTableFooter
{
    self.tableView.tableFooterView = self.tableFooterView;
}

- (void)openTrackOnSoundcloud:(Track *)track
{
    NSURL *nativeAppTrackURL = [NSURL URLWithString:[NSString stringWithFormat:@"soundcloud:tracks:%@", track.trackId]];
    
    if ([[UIApplication sharedApplication] canOpenURL:nativeAppTrackURL]) {
        [[UIApplication sharedApplication] openURL:nativeAppTrackURL];
    } else {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:track.permalinkURL]];
    }
}

- (void)refreshFeed
{
    [feedController refreshFeedWithCompletionHandler:^(NSError *error) {
        isCurrentlyloadingMoreResults = NO;
        
        if ([self hasSupportForPullToRefresh]) {
            [self.refreshControl endRefreshing];
        }
    }];
}

- (void)reloadAccount
{
    [feedController loadAccountWithCompletionHandler:^(NSError *error) {
        if (!error) {
            [self dismissViewControllerAnimated:YES completion:nil];
            [self resetFetchRequest];
            
            if ([feedController.account.feed count] == 0) {
                [self refreshFeed];
            }
        }
    }];
}

- (void)loadMoreResultsIfCloseToTheBottom
{
    CGFloat distanceToBottom = self.tableView.contentSize.height - (self.tableView.contentOffset.y + self.tableView.frame.size.height);
    
    if (distanceToBottom < 200 && !isCurrentlyloadingMoreResults) {
        isCurrentlyloadingMoreResults  = YES;
        
        if (feedController.moreResultsAreAvailable) {
            [self showTableFooter];
        }
        
        [feedController loadMoreFeedResultsWithCompletionHandler:^(NSError *error) {
            if (error) {
                NSLog(@"Could not load more feed results %@", error);
            }
            
            if (!feedController.moreResultsAreAvailable) {
                [self hideTableFooter];
            }
            
            isCurrentlyloadingMoreResults = NO;
        }];
    }
}

- (void)configureTrackCell:(UITableViewCell *)cell track:(Track *)track
{
    if (cell == nil) return;
    
    UILabel *artistLabel = (UILabel *)[cell viewWithTag:TAG_TRACK_ARTIST_LABEL];
    UILabel *titleLabel = (UILabel *)[cell viewWithTag:TAG_TRACK_TITLE_LABEL];
    UILabel *dateLabel = (UILabel *)[cell viewWithTag:TAG_TRACK_DATE_LABEL];
    UIImageView *artworkImageView = (UIImageView *)[cell viewWithTag:TAG_TRACK_ARTWORK_IMAGE_VIEW];
    //UIImageView *waveformImageView = (UIImageView *)[cell viewWithTag:TAG_TRACK_WAVEFORM_IMAGE_VIEW];
    WaveformView *waveformView = (WaveformView *)[cell viewWithTag:6];
    
    artistLabel.text = track.artistName;
    titleLabel.text = track.title;
    dateLabel.text = [dateFormatter stringFromDate:track.createdAt];
    [artworkImageView setImageWithURL:[NSURL URLWithString:track.artworkURL] placeholderImage:nil];
    //[waveformImageView setImageWithURL:[NSURL URLWithString:track.waveformURL] placeholderImage:nil];
    
    [[SDWebImageManager sharedManager] downloadWithURL:[NSURL URLWithString:track.waveformURL] options:0 progress:nil completed:
     ^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished) {
         if (!error && finished) {
             waveformView.waveformImage = image;
         }
     }];
}

#pragma mark - LoginViewController delegate methods

- (void)loginViewControllerDidLogin:(LoginViewController *)sender
{
    [self reloadAccount];
}

- (void)loginViewControllerDidCancel:(LoginViewController *)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)viewDidUnload {
    [self setTableView:nil];
    [self setTrackTableViewCell:nil];
    [self setTableFooterView:nil];
    [super viewDidUnload];
}

#pragma mark - UIScrollView delegate methods

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    [self loadMoreResultsIfCloseToTheBottom];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [self loadMoreResultsIfCloseToTheBottom];
}

#pragma mark - UITableView delegate methods

- (void)tableView:(UITableView *)tableView didHighlightRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self openTrackOnSoundcloud:[fetchedResultsController objectAtIndexPath:indexPath]];
}

#pragma mark - NSTableViewDatasource delegate methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [[fetchedResultsController sections] count];
}

- (NSInteger)tableView:(UITableView *)table numberOfRowsInSection:(NSInteger)section {
    id <NSFetchedResultsSectionInfo> sectionInfo = [[fetchedResultsController sections] objectAtIndex:section];
    return [sectionInfo numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"TrackTableViewCell"];
    if (cell == nil) {
        [[NSBundle mainBundle] loadNibNamed:@"TrackTableViewCell" owner:self options:nil];
        self.trackTableViewCell.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"gradient.png"]];
        self.trackTableViewCell.selectedBackgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"gradient.png"]];
        
        
        CALayer *layer = [self.trackTableViewCell viewWithTag:TAG_TRACK_ARTWORK_IMAGE_VIEW].layer;
        layer.cornerRadius = 4.0;
        layer.borderWidth = 1.0;
        layer.borderColor = [UIColor darkGrayColor].CGColor;
        
        cell = self.trackTableViewCell;
        self.trackTableViewCell = nil;
    }
    
    [self configureTrackCell:cell track:[fetchedResultsController objectAtIndexPath:indexPath]];
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    id <NSFetchedResultsSectionInfo> sectionInfo = [[fetchedResultsController sections] objectAtIndex:section];
    return [sectionInfo name];
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    return [fetchedResultsController sectionIndexTitles];
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index {
    return [fetchedResultsController sectionForSectionIndexTitle:title atIndex:index];
}

#pragma mark - NSFetchedResultsController delegate methods

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView beginUpdates];
}


- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type {
    
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex]
                          withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex]
                          withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}


- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath {
    
    UITableView *tableView = self.tableView;
    
    switch(type) {
            
        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]
                             withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                             withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate:
            [self configureTrackCell:[tableView cellForRowAtIndexPath:indexPath]
                               track:[fetchedResultsController objectAtIndexPath:indexPath]];
            break;
            
        case NSFetchedResultsChangeMove:
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                             withRowAnimation:UITableViewRowAnimationFade];
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]
                             withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}


- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView endUpdates];
}

@end
