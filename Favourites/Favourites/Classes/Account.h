//
//  Account.h
//  Favourites
//
//  Created by Jacob Persson on 2012-12-17.
//  Copyright (c) 2012 Jacob Persson. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Track;

@interface Account : NSManagedObject

@property (nonatomic, retain) NSNumber * accountId;
@property (nonatomic, retain) NSString * fullName;
@property (nonatomic, retain) NSString * avatarURL;
@property (nonatomic, retain) NSString * username;
@property (nonatomic, retain) NSSet *feed;
@end

@interface Account (CoreDataGeneratedAccessors)

- (void)addFeedObject:(Track *)value;
- (void)removeFeedObject:(Track *)value;
- (void)addFeed:(NSSet *)values;
- (void)removeFeed:(NSSet *)values;

@end
