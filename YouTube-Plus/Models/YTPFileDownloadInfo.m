//
//  FileDownloadInfo.m
//  YouTubePlus
//
//  Created by Paul Wong on 25/3/14.
//  Copyright (c) 2014 Appcoda. All rights reserved.
//

#import "YTPFileDownloadInfo.h"

@implementation YTPFileDownloadInfo

- (id)initWithFileName:(NSString *)name andTitle:(NSString *)title andDownloadSource:(NSString *)source {
    if (self == [super init]) {
        self.fileName = name;
        self.fileTitle = title;
        self.downloadSource = source;
        self.downloadProgress = 0.0;
        self.isDownloading = NO;
        self.downloadComplete = NO;
        self.taskIdentifier = -1;
    }
    
    return self;
}

@end
