//
//  YTPNavigationController.m
//  BGTransferDemo
//
//  Created by Paul Wong on 11/17/14.
//  Copyright (c) 2014 Appcoda. All rights reserved.
//

#import "YTPNavigationController.h"

@interface YTPNavigationController ()

@end

@implementation YTPNavigationController

- (BOOL)shouldAutorotate {
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

@end
