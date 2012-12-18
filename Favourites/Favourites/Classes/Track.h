//
//  Track.h
//  Favourites
//
//  Created by Jacob Persson on 2012-12-18.
//  Copyright (c) 2012 Jacob Persson. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "Account.h"

@class Account;

@interface Track : Account

@property (nonatomic, retain) NSString * artworkURL;
@property (nonatomic, retain) NSDate * createdAt;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSNumber * trackId;
@property (nonatomic, retain) NSString * waveformURL;
@property (nonatomic, retain) NSString * artistName;
@property (nonatomic, retain) NSString * permalinkURL;
@property (nonatomic, retain) Account *account;

@end
