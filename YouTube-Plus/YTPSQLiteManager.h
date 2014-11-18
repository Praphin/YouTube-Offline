//
//  YTPSQLiteManager.h
//  Vinous
//
//  Created by Baoluo Wang on 8/15/14.
//  Copyright (c) 2014 Paul Wong. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface YTPSQLiteManager : NSObject

+ (id)sharedManager;
- (void)checkAndCreateDatabase;

- (void)addToVideosWithName:(NSString *)videoName url:(NSString *)videoUrl path:(NSString *)videoPath state:(NSString *)videoState;
- (void)markVideoAsComplete:(NSString *)path;

- (void)removeVideo:(NSString *)path;
- (void)removeRecentVideos;

- (NSMutableArray *)recentVideos;

@end
