//
//  YTPSQLiteManager.m
//  Vinous
//
//  Created by Baoluo Wang on 8/15/14.
//  Copyright (c) 2014 Paul Wong. All rights reserved.
//

#import "YTPSQLiteManager.h"
#import "FMDatabase.h"
#import "YTPVideo.h"
#import <sqlite3.h>

@interface YTPSQLiteManager()

@property (nonatomic) NSString *databaseName;
@property (nonatomic) NSString *databasePath;

@end

@implementation YTPSQLiteManager

+ (id)sharedManager {
    static id sharedManager = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[self alloc] init];
    });
    
    return sharedManager;
}

- (void)checkAndCreateDatabase {
    self.databaseName = @"YTP-DB.sql";
    NSArray *documentPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDir = [documentPaths objectAtIndex:0];
    self.databasePath = [documentsDir stringByAppendingPathComponent:self.databaseName];
    
    BOOL success;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    success = [fileManager fileExistsAtPath:self.databasePath];
    NSLog(@"Success: %d", success);
    
    // If the database already exists, then do nothing more
    if (success) {
        return;
    }
    else {
        // If not, then copy the database from the application
        NSError *error;
        NSString *databasePathFromApp = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:self.databaseName];
        if (![fileManager copyItemAtPath:databasePathFromApp toPath:self.databasePath error:&error]) {
            // Handle error
            NSLog(@"Copying error: %@", error);
        }
    }
}

// CREATE TABLE youtube_videos ( id INTEGER PRIMARY KEY, name VARCHAR(255), path VARCHAR(255), state VARCHAR(20) );
- (void)addToVideosWithName:(NSString *)videoName url:(NSString *)videoUrl path:(NSString *)videoPath state:(NSString *)videoState {
    FMDatabase *database = [FMDatabase databaseWithPath:self.databasePath];
    
    [database open];
    BOOL success = [database executeUpdate:@"INSERT INTO youtube_videos (name, url, path, state) VALUES (?, ?, ?, ?)", videoName, videoUrl, videoPath, videoState];
    [database close];
    
    if (success) {
        NSLog(@"Successfully add this to youtube videos.");
    }
    else {
        NSLog(@"Fail to add this to youtube videos.");
    }
}

- (void)markVideoAsComplete:(NSString *)path {
    FMDatabase *database = [FMDatabase databaseWithPath:self.databasePath];
    
    [database open];
    BOOL success = [database executeUpdate:@"UPDATE youtube_videos SET state = ? WHERE path = ?", @"Complete", path];
    [database close];
    
    if (success) {
        NSLog(@"Successfully update this video as downloaded.");
    }
    else {
        NSLog(@"Fail to update this video as downloaded.");
    }
}

- (void)removeVideo:(NSString *)path {
    FMDatabase *database = [FMDatabase databaseWithPath:self.databasePath];
    
    [database open];
    BOOL success = [database executeUpdate:@"DELETE FROM youtube_videos WHERE path = ?", path];
    [database close];
    
    if (success) {
        NSLog(@"Successfully remove this video.");
        
        // Delete the corresponding video file.
        NSFileManager *fileManager = [NSFileManager defaultManager];
        
        NSArray *URLs = [[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
        NSURL *docDirectoryURL = [URLs objectAtIndex:0];
        NSString *destinationFilename = [NSString stringWithFormat:@"%@.mp4", path];
        NSURL *destinationURL = [docDirectoryURL URLByAppendingPathComponent:destinationFilename];
        
        if ([fileManager fileExistsAtPath:[destinationURL path]]) {
            [fileManager removeItemAtURL:destinationURL error:nil];
        }
    }
    else {
        NSLog(@"Fail to remove this video.");
    }
}

- (void)removeRecentVideos {
    FMDatabase *database = [FMDatabase databaseWithPath:self.databasePath];
    
    [database open];
    BOOL success = [database executeUpdate:@"DELETE FROM youtube_videos"];
    [database close];
    
    if (success) {
        NSLog(@"Successfully remove recent videos.");
    }
    else {
        NSLog(@"Fail to remove recent videos.");
    }
}

- (NSMutableArray *)recentVideos {
    FMDatabase *database = [FMDatabase databaseWithPath:self.databasePath];
    
    [database open];
    NSMutableArray *youtubeVideos = [[NSMutableArray alloc] init];
    FMResultSet *results = [database executeQuery:@"SELECT * FROM youtube_videos ORDER BY id DESC"];
    while ([results next]) {
        YTPVideo *video = [[YTPVideo alloc] initWithId:[results intForColumn:@"id"] name:[results stringForColumn:@"name"] url:[results stringForColumn:@"url"] path:[results stringForColumn:@"path"] state:[results stringForColumn:@"state"]];
        [youtubeVideos addObject:video];
    }
    [database close];
    
    return youtubeVideos;
}

@end
