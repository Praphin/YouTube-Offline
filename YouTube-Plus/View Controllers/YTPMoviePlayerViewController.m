//
//  YTPMoviePlayerViewController.m
//  BGTransferDemo
//
//  Created by Paul Wong on 11/17/14.
//  Copyright (c) 2014 Appcoda. All rights reserved.
//

#import "YTPMoviePlayerViewController.h"

@interface YTPMoviePlayerViewController ()

@end

@implementation YTPMoviePlayerViewController

// Enable automatic landscape YouTube video playing!  :)

- (BOOL)shouldAutorotate {
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskLandscape;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return UIInterfaceOrientationIsLandscape(toInterfaceOrientation);
}

@end