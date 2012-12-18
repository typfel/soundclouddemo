//
//  FeedController.h
//  Favourites
//
//  Created by Jacob Persson on 2012-12-13.
//  Copyright (c) 2012 Jacob Persson. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Account.h"

typedef enum _FeedControllerError {
    FeedControllerErrorNoMoreData = 'noda'
} FeedControllerError;

typedef void(^FeedControllerCompletionHandler)(NSError *error);

@interface FeedController : NSObject

- (void)loadAccountWithCompletionHandler:(FeedControllerCompletionHandler)completionHandler;
- (void)refreshFeedWithCompletionHandler:(FeedControllerCompletionHandler)completionHandler;
- (void)loadMoreFeedResultsWithCompletionHandler:(FeedControllerCompletionHandler)completionHandler;

@property (readonly, nonatomic) Account *account;
@property (readonly, nonatomic) BOOL moreResultsAreAvailable;

@end
