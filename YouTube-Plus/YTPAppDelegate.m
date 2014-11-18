//
//  AppDelegate.m
//  YouTubePlus
//
//  Created by Paul Wong on 25/3/14.
//  Copyright (c) 2014 Appcoda. All rights reserved.
//

#import "YTPAppDelegate.h"
#import "YTPSQLiteManager.h"
#import <MediaPlayer/MediaPlayer.h>

#define barTintColor [UIColor colorWithRed:195.0/255.0f green:13.0/255.0f blue:10.0/255.0f alpha:1.0f]
#define tintColor [UIColor whiteColor]

@implementation YTPAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [[YTPSQLiteManager sharedManager] checkAndCreateDatabase];
    
    // Define nav bar appearance.
    [[UINavigationBar appearance] setBarStyle:UIBarStyleBlack];
    [[UINavigationBar appearance] setBarTintColor:barTintColor];
    [[UINavigationBar appearance] setTintColor:tintColor];
    [[UINavigationBar appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName: tintColor, NSFontAttributeName: [UIFont fontWithName:@"AvenirNext-Medium" size:18]}];
    
    [[UIBarButtonItem appearanceWhenContainedIn:[MPMoviePlayerViewController class], nil] setTitleTextAttributes:@{NSFontAttributeName: [UIFont fontWithName:@"AvenirNext-Regular" size:17]} forState:UIControlStateNormal];

    // Define tab bar appearance.
    [[UITabBar appearance] setTintColor:barTintColor];
        
    // Set status bar style.
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    
    // Set the network activity indicator to be shown.
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];

    return YES;
}


-(void)application:(UIApplication *)application handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:(void (^)())completionHandler {
    self.backgroundTransferCompletionHandler = completionHandler;
}


- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
