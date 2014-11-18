//
//  YTPHomeViewController.h
//  YouTubePlus
//
//  Created by Paul Wong on 25/3/14.
//  Copyright (c) 2014 Appcoda. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface YTPHomeViewController : UITableViewController <NSURLSessionDelegate, UIAlertViewDelegate>

- (void)startOrPauseDownloadingSingleFile:(id)sender;

- (void)stopDownloading:(id)sender;

@end
