//
//  FileDownloadInfo.h
//  YouTubePlus
//
//  Created by Paul Wong on 25/3/14.
//  Copyright (c) 2014 Appcoda. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface YTPFileDownloadInfo : NSObject

@property (nonatomic) NSString *fileName; // "Interstellar"

@property (nonatomic, strong) NSString *fileTitle; // "dghidgaihXhd"

@property (nonatomic, strong) NSString *downloadSource;

@property (nonatomic, strong) NSURLSessionDownloadTask *downloadTask;

@property (nonatomic, strong) NSData *taskResumeData;

@property (nonatomic) double downloadProgress;

@property (nonatomic) BOOL isDownloading;

@property (nonatomic) BOOL downloadComplete;

@property (nonatomic) unsigned long taskIdentifier;

- (id)initWithFileName:(NSString *)name andTitle:(NSString *)title andDownloadSource:(NSString *)source;

@end
