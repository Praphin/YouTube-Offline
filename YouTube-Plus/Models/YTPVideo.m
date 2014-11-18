//
//  YTPVideo.m
//  BGTransferDemo
//
//  Created by Paul Wong on 11/16/14.
//  Copyright (c) 2014 Appcoda. All rights reserved.
//

#import "YTPVideo.h"

@implementation YTPVideo

- (instancetype)initWithId:(NSInteger)videoId name:(NSString *)videoName url:(NSString *)videoUrl path:(NSString *)videoPath state:(NSString *)videoState {
    self = [super init];
    if (self) {
        self.videoId = videoId;
        self.videoName = videoName;
        self.videoUrl = videoUrl;
        self.videoPath = videoPath;
        self.videoState = videoState;
    }
    return self;
}

@end
