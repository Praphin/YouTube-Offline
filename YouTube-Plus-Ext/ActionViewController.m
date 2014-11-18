//
//  ActionViewController.m
//  YouTube-Plus-Ext
//
//  Created by Paul Wong on 11/17/14.
//  Copyright (c) 2014 Appcoda. All rights reserved.
//

#import "ActionViewController.h"
#import <MobileCoreServices/MobileCoreServices.h>

#define barTintColor [UIColor colorWithRed:195.0/255.0f green:13.0/255.0f blue:10.0/255.0f alpha:1.0f]
#define tintColor [UIColor whiteColor]

@interface ActionViewController ()

@property (strong, nonatomic) IBOutlet UIButton *buttonDownloadVideo;
@property (nonatomic) UIBarButtonItem *barButtonItemCancel;

@end

@implementation ActionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Define nav bar appearance.
    [[UINavigationBar appearance] setBarStyle:UIBarStyleBlack];
    [[UINavigationBar appearance] setBarTintColor:barTintColor];
    [[UINavigationBar appearance] setTintColor:tintColor];
    [[UINavigationBar appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName: tintColor, NSFontAttributeName: [UIFont fontWithName:@"AvenirNext-Medium" size:18]}];
    [[UIBarButtonItem appearanceWhenContainedIn:[UINavigationBar class], nil] setTitleTextAttributes:@{NSFontAttributeName: [UIFont fontWithName:@"AvenirNext-Regular" size:17]} forState:UIControlStateNormal];
    
    self.buttonDownloadVideo.layer.cornerRadius = 3.0f;
    self.buttonDownloadVideo.layer.masksToBounds = YES;
    
    self.barButtonItemCancel = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel)];
    self.navigationItem.leftBarButtonItem = self.barButtonItemCancel;
    
    BOOL urlFound = NO;
    __weak typeof(self) weakSelf = self;
    for (NSExtensionItem *item in self.extensionContext.inputItems) {
        for (NSItemProvider *itemProvider in item.attachments) {
            if ([itemProvider hasItemConformingToTypeIdentifier:(NSString *)kUTTypeURL]) {
                // YouTube video link is received.
                [itemProvider loadItemForTypeIdentifier:(NSString *)kUTTypeURL options:nil completionHandler:^(NSURL *url, NSError *error) {
                    if (url) {
                        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                            weakSelf.labelYouTubeLink.text = url.absoluteString;
                        }];
                    }
                }];
                
                urlFound = YES;
                break;
            }
        }
        
        if (urlFound) {
            // We only handle one url, so stop looking for more.
            break;
        }
    }
}

- (void)beginRequestWithExtensionContext:(NSExtensionContext *)context {
    [super beginRequestWithExtensionContext:context];
    NSLog(@"container: beginRequestWithExtensionContext");
}

- (IBAction)cancel {
    [self.extensionContext completeRequestReturningItems:nil completionHandler:nil];
}

- (IBAction)done {
    // Return any edited content to the host app.
    // This template doesn't do anything, so we just echo the passed in items.
    [self.extensionContext completeRequestReturningItems:self.extensionContext.inputItems completionHandler:nil];
}

@end
