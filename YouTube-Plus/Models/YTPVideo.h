//
//  YTPVideo.h
//  BGTransferDemo
//
//  Created by Paul Wong on 11/16/14.
//  Copyright (c) 2014 Appcoda. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface YTPVideo : NSObject

@property (nonatomic) NSInteger videoId;
@property (nonatomic) NSString *videoName;
@property (nonatomic) NSString *videoUrl;
@property (nonatomic) NSString *videoPath;
@property (nonatomic) NSString *videoState;

- (instancetype)initWithId:(NSInteger)videoId name:(NSString *)videoName url:(NSString *)videoUrl path:(NSString *)videoPath state:(NSString *)videoState;

@end
