//
//  YTPTableViewCell.h
//  BGTransferDemo
//
//  Created by Paul Wong on 11/17/14.
//  Copyright (c) 2014 Appcoda. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface YTPTableViewCell : UITableViewCell

@property (strong, nonatomic) IBOutlet UILabel *displayTitle;
@property (strong, nonatomic) IBOutlet UIButton *startPauseButton;
@property (strong, nonatomic) IBOutlet UIButton *stopButton;
@property (strong, nonatomic) IBOutlet UIProgressView *progressView;
@property (strong, nonatomic) IBOutlet UILabel *readyLabel;

@end