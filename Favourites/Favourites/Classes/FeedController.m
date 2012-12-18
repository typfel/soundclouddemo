//
//  FeedController.m
//  Favourites
//
//  Created by Jacob Persson on 2012-12-13.
//  Copyright (c) 2012 Jacob Persson. All rights reserved.
//

#import "SCAPI.h"

#import "FeedController.h"
#import "AppDelegate.h"
#import "Track.h"
#import "Account.h"

#define SOUNDCLOUD_ENDPOINT_URL @"https://api.soundcloud.com"

#define keyAccountId @"accountId"

#define unboxNullValue(VAL) ([VAL isKindOfClass:[NSNull class]] ? nil : VAL)

@interface FeedController () {
    NSDateFormatter *dateFormatter;
    NSString *nextResultsHref;
}

@end

@implementation FeedController

- (id)init
{
    self = [super init];
    if (self) {
        nextResultsHref = nil;
        
        // 2011/04/06 15:37:43 +0000
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy'/'MM'/'dd kk':'mm':'ss ZZZ"];
        [dateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSNumber *accountId = [defaults valueForKey:keyAccountId];
        
        if (accountId) {
            NSLog(@"loading existing account %@", accountId);
            
            NSError *error;
            _account = [self accountAssociatedWithId:accountId.intValue error:&error];
            
            if (error) {
                NSLog(@"Couldn't load existing account");
                // reset account
                [defaults removeObjectForKey:keyAccountId];
                [defaults synchronize];
            }
        }
    }
    return self;
}

- (void)saveContext
{
    [(AppDelegate *)[[UIApplication sharedApplication] delegate] saveContext];
}

- (NSManagedObjectContext *)managedObjectContext
{
    return [(AppDelegate *)[[UIApplication sharedApplication] delegate] managedObjectContext];
}

- (Account *)accountAssociatedWithId:(NSInteger)accountId error:(NSError **)error
{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Account"];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"accountId = %@", @(accountId)];
    
    NSArray *results = [[appDelegate managedObjectContext] executeFetchRequest:fetchRequest error:error];
    return [results count] > 0 ? [results lastObject] : nil;
}

- (void)loadAccountWithCompletionHandler:(FeedControllerCompletionHandler)completionHandler
{
    NSURL *soundcloudEndpoint = [NSURL URLWithString:SOUNDCLOUD_ENDPOINT_URL];
    NSURL *meURL = [NSURL URLWithString:@"me.json" relativeToURL:soundcloudEndpoint];
    
    [SCRequest performMethod:SCRequestMethodGET
                  onResource:meURL
             usingParameters:nil
                 withAccount:[SCSoundCloud account]
      sendingProgressHandler:nil
             responseHandler:^(NSURLResponse *response, NSData *responseData, NSError *error) {
                 
                 if (error) {
                     completionHandler(error);
                     return;
                 }
                 
                 NSError *jsonError;
                 id jsonResponse = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:&jsonError];
                 
                 if (jsonError) {
                     completionHandler(jsonError);
                     return;
                 }
                 
                 NSNumber *accountId = [jsonResponse valueForKey:@"id"];
                 
                 if (self.account == nil || ![self.account.accountId isEqualToNumber:accountId]) {
                     Account *account = [self insertAccountFromJSON:jsonResponse];
                     
                     [self saveContext];
                     
                     NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                     [defaults setValue:accountId forKey:keyAccountId];
                     [defaults synchronize];
                     
                     _account = account;
                     nextResultsHref = nil;
                 } else {
                     // update account
                 }
                 
                 completionHandler(nil);
             }];
}

- (void)refreshFeedWithCompletionHandler:(FeedControllerCompletionHandler)completionHandler
{
    NSURL *soundcloudEndpoint = [NSURL URLWithString:SOUNDCLOUD_ENDPOINT_URL];
    NSURL *activitiesURL = [NSURL URLWithString:@"me/activities/tracks/affiliated.json" relativeToURL:soundcloudEndpoint];
    
    [SCRequest performMethod:SCRequestMethodGET
                  onResource:activitiesURL
             usingParameters:@{ @"limit" : @"15" }
                 withAccount:[SCSoundCloud account]
      sendingProgressHandler:nil
             responseHandler:^(NSURLResponse *response, NSData *responseData, NSError *error) {
                 
                 if (error) {
                     completionHandler(error);
                     return;
                 }
                 
                 NSError *jsonError;
                 id jsonResponse = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:&jsonError];
                 
                 if (jsonError) {
                     completionHandler(jsonError);
                     return;
                 }
                 
                 nextResultsHref = unboxNullValue([jsonResponse valueForKey:@"next_href"]);
                 
                 for (Track *track in self.account.feed) {
                     [[self managedObjectContext] deleteObject:track];
                 }
                 [self.account setFeed:nil];
                 
                 for (id jsonTrack in [jsonResponse valueForKey:@"collection"]) {
                     Track *track = [self insertTrackFromJSON:jsonTrack];
                     [self.account addFeedObject:track];
                 }
                 
                 [self saveContext];
                 
                 completionHandler(nil);
             }];
}

- (void)loadMoreFeedResultsWithCompletionHandler:(FeedControllerCompletionHandler)completionHandler
{
    if (!nextResultsHref) {
        completionHandler(nil);
        return;
    }
    
    [SCRequest performMethod:SCRequestMethodGET
                  onResource: [[NSURL URLWithString:nextResultsHref] URLByAppendingPathExtension:@"json"]
             usingParameters:nil
                 withAccount:[SCSoundCloud account]
      sendingProgressHandler:nil
             responseHandler:^(NSURLResponse *response, NSData *responseData, NSError *error) {                 
                 if (error) {
                     completionHandler(error);
                     return;
                 }
                 
                 NSError *jsonError;
                 id jsonResponse = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:&jsonError];
                 
                 if (jsonError) {
                     completionHandler(jsonError);
                     return;
                 }
                 
                 nextResultsHref = unboxNullValue([jsonResponse valueForKey:@"next_href"]);
                 
                 for (id jsonTrack in [jsonResponse valueForKey:@"collection"]) {
                     Track *track = [self insertTrackFromJSON:jsonTrack];
                     [self.account addFeedObject:track];
                 }
                 
                 [self saveContext];
                 
                 completionHandler(nil);
             }];
}

- (BOOL)moreResultsAreAvailable
{
    return nextResultsHref != nil;
}

- (Account *)insertAccountFromJSON:(id)json
{    
    Account *account = (Account *)[NSEntityDescription insertNewObjectForEntityForName:@"Account" inManagedObjectContext:[self managedObjectContext]];
    
    account.accountId = [json valueForKeyPath:@"id"];
    account.fullName = [json valueForKeyPath:@"full_name"];
    account.username = [json valueForKeyPath:@"username"];
    account.avatarURL = unboxNullValue([json valueForKeyPath:@"avatar_url"]);
    
    return account;
}

- (Track *)insertTrackFromJSON:(id)json
{    
    Track *track = (Track *)[NSEntityDescription insertNewObjectForEntityForName:@"Track" inManagedObjectContext:[self managedObjectContext]];
    
    track.trackId = [json valueForKeyPath:@"origin.id"];
    track.title = [json valueForKeyPath:@"origin.title"];
    track.artistName = [json valueForKeyPath:@"origin.user.username"];
    track.createdAt = [dateFormatter dateFromString:[json valueForKeyPath:@"origin.created_at"]];
    track.artworkURL = unboxNullValue([json valueForKeyPath:@"origin.artwork_url"]);
    track.waveformURL = unboxNullValue([json valueForKeyPath:@"origin.waveform_url"]);
    track.permalinkURL = unboxNullValue([json valueForKeyPath:@"origin.permalink_url"]);
        
    return track;
}

@end
