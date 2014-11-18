//
//  YTPHomeViewController.m
//  YouTubePlus
//
//  Created by Paul Wong on 25/3/14.
//  Copyright (c) 2014 Appcoda. All rights reserved.
//

#import <MediaPlayer/MediaPlayer.h>
#import "YTPHomeViewController.h"
#import "YTPFileDownloadInfo.h"
#import "YTPAppDelegate.h"
#import "HCYoutubeParser.h"
#import "YTPSQLiteManager.h"
#import "YTPVideo.h"
#import "YTPTableViewCell.h"
#import "YTPMoviePlayerViewController.h"

@interface YTPHomeViewController ()

@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, strong) NSMutableArray *arrFileDownloadData;
@property (nonatomic, strong) NSURL *docDirectoryURL;

@property (nonatomic, strong) NSMutableArray *recentVideos;

@property (nonatomic) UIBarButtonItem *barButtonItemAdd;
@property (nonatomic) UITextField *textFieldVideoName;
@property (nonatomic) UITextField *textFieldYouTubeUrl;

- (void)initializeFileDownloadDataArray;
- (int)getFileDownloadInfoIndexWithTaskIdentifier:(unsigned long)taskIdentifier;

@end

@implementation YTPHomeViewController

#pragma mark - View Controller Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self initializeFileDownloadDataArray];
    
    NSArray *URLs = [[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
    self.docDirectoryURL = [URLs objectAtIndex:0];
    
    NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:@"com.YouTubePlus"];
    sessionConfiguration.HTTPMaximumConnectionsPerHost = 5;
    
    self.session = [NSURLSession sessionWithConfiguration:sessionConfiguration
                                                 delegate:self
                                            delegateQueue:nil];
    
    self.barButtonItemAdd = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"add_youtube_video"] style:UIBarButtonItemStylePlain target:self action:@selector(downloadNewYouTubeVideo)];
    self.navigationItem.rightBarButtonItem = self.barButtonItemAdd;
}

#pragma mark - Private Methods

- (void)downloadNewYouTubeVideo {
    UIAlertView *alertView =[[UIAlertView alloc] initWithTitle:@"New Video" message:@"Please enter the YouTube video url, and name the video." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Download", nil];
    alertView.alertViewStyle = UIAlertViewStyleLoginAndPasswordInput;

    self.textFieldYouTubeUrl = [alertView textFieldAtIndex:0];
    self.textFieldYouTubeUrl.placeholder = @"http://";
    
    self.textFieldVideoName = [alertView textFieldAtIndex:1];
    self.textFieldVideoName.secureTextEntry = NO;
    self.textFieldVideoName.placeholder = @"Name this video.";
    self.textFieldVideoName.autocapitalizationType = UITextAutocapitalizationTypeWords;
    
    BOOL youtubeVideoUrlDetected = NO;
    UIPasteboard *pb = [UIPasteboard generalPasteboard];
    if ([[[pb string] lowercaseString] containsString:@"youtube"]) {
        self.textFieldYouTubeUrl.text = [pb string];
        youtubeVideoUrlDetected = YES;
    }
    
    if (youtubeVideoUrlDetected) {
        alertView.message = @"We detect a YouTube video url!\nOr, you can still manually enter the url.";
        [self.textFieldYouTubeUrl resignFirstResponder];
    }
    
    [alertView show];
}

- (void)submitYouTubeURL {
    NSString *name = [self.textFieldVideoName.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    NSURL *url = [NSURL URLWithString:[self.textFieldYouTubeUrl.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]];
    
    [HCYoutubeParser thumbnailForYoutubeURL:url thumbnailSize:YouTubeThumbnailDefaultHighQuality completeBlock:^(UIImage *image, NSError *error) {
        
        if (!error) {
            
            [HCYoutubeParser h264videosWithYoutubeURL:url completeBlock:^(NSDictionary *videoDictionary, NSError *error) {
                
                NSDictionary *qualities = videoDictionary;
                
                // NSLog(@"Video Dictionary: %@", videoDictionary);
                // "small", "medium", "hd720", and more...
                
                NSString *URLString = nil;
                if ([qualities objectForKey:@"medium"] != nil) {
                    URLString = [qualities objectForKey:@"medium"];
                }
                else if ([qualities objectForKey:@"live"] != nil) {
                    URLString = [qualities objectForKey:@"live"];
                }
                else {
                    [[[UIAlertView alloc] initWithTitle:@"Error" message:@"Couldn't find youtube video" delegate:nil cancelButtonTitle:@"Close" otherButtonTitles: nil] show];
                    return;
                }
                
                // Start downloading this video.
                // https://m.youtube.com/watch%3Fv=zCbfWGgp9qs => "zCbfWGgp9qs"
                NSString *title = [url.relativeString substringFromIndex:url.relativeString.length - 11];
                YTPFileDownloadInfo *fileDownloadInfo = [[YTPFileDownloadInfo alloc] initWithFileName:name andTitle:title andDownloadSource:URLString];
                [self downloadSingleFile:fileDownloadInfo];
                
                fileDownloadInfo.downloadComplete = NO;
                
                // Save the video metadata info into SQLite
                // (@"Incomplete", will be changed to be "Complete" when the download is finished.).
                [[YTPSQLiteManager sharedManager] addToVideosWithName:name url:URLString path:title state:@"Incomplete"];
            }];
        }
        else {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:[error localizedDescription] delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil];
            [alert show];
        }
    }];
}

- (void)initializeFileDownloadDataArray {
    self.arrFileDownloadData = [[NSMutableArray alloc] init];
    self.recentVideos = [[YTPSQLiteManager sharedManager] recentVideos];
    for (YTPVideo *video in self.recentVideos) {
        YTPFileDownloadInfo *fdi = [[YTPFileDownloadInfo alloc] initWithFileName:video.videoName andTitle:video.videoPath andDownloadSource:video.videoUrl];
        if ([video.videoState isEqualToString:@"Incomplete"]) {
            fdi.downloadComplete = NO;
        }
        else {
            fdi.downloadComplete = YES;
        }
        
        [self.arrFileDownloadData addObject:fdi];
    }
}

- (int)getFileDownloadInfoIndexWithTaskIdentifier:(unsigned long)taskIdentifier {
    int index = 0;
    for (int i=0; i<[self.arrFileDownloadData count]; i++) {
        YTPFileDownloadInfo *fdi = [self.arrFileDownloadData objectAtIndex:i];
        if (fdi.taskIdentifier == taskIdentifier) {
            index = i;
            break;
        }
    }
    
    return index;
}

#pragma mark - UITableView DataSource and Delegate

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        YTPFileDownloadInfo *fdi = [self.arrFileDownloadData objectAtIndex:indexPath.row];
        
        // Remove from database.
        [[YTPSQLiteManager sharedManager] removeVideo:fdi.fileTitle];
        
        // Remove from datasource.
        if (indexPath.row < self.arrFileDownloadData.count) {
            [self.arrFileDownloadData removeObjectAtIndex:indexPath.row];
        }
        if (indexPath.row < self.recentVideos.count) {
            [self.recentVideos removeObjectAtIndex:indexPath.row];
        }
        
        // Reflect UI change.
        [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationLeft];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    self.recentVideos = [[YTPSQLiteManager sharedManager] recentVideos];
    YTPVideo *video = [self.recentVideos objectAtIndex:indexPath.row];
    
    if ([video.videoState isEqualToString:@"Complete"]) {
        // in iOS8  :)  555555...
        NSURL *destinationURL = [[[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject] URLByAppendingPathComponent:[NSString stringWithFormat:@"%@.mp4", video.videoPath]];
        
        YTPMoviePlayerViewController *moviePlayerViewController = [[YTPMoviePlayerViewController alloc] initWithContentURL:destinationURL];
        
        [self presentMoviePlayerViewControllerAnimated:moviePlayerViewController];
        [moviePlayerViewController.moviePlayer prepareToPlay];
        [moviePlayerViewController.moviePlayer play];
    }

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.arrFileDownloadData.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    YTPTableViewCell *cell = [[YTPTableViewCell alloc] initWithFrame:CGRectZero];
    YTPFileDownloadInfo *fdi = [self.arrFileDownloadData objectAtIndex:indexPath.row];
    
    UILabel *displayTitle = cell.displayTitle;
    UIButton *startPauseButton = cell.startPauseButton;
    UIButton *stopButton = cell.stopButton;
    UIProgressView *progressView = cell.progressView;
    UILabel *readyLabel = cell.readyLabel;
    readyLabel.layer.cornerRadius = 3.0f;
    readyLabel.layer.masksToBounds = YES;
    readyLabel.layer.borderWidth = 1.0f;
    readyLabel.layer.borderColor = readyLabel.textColor.CGColor;
    
    [startPauseButton addTarget:self action:@selector(startOrPauseDownloadingSingleFile:) forControlEvents:UIControlEventTouchUpInside];
    [stopButton addTarget:self action:@selector(stopDownloading:) forControlEvents:UIControlEventTouchUpInside];
    
    NSString *startPauseButtonImageName;
    
    displayTitle.text = fdi.fileName;
    
    if (!fdi.isDownloading) {
        progressView.hidden = YES;
        stopButton.enabled = NO;

        BOOL hideControls = (fdi.downloadComplete) ? YES : NO;
        startPauseButton.hidden = hideControls;
        stopButton.hidden = hideControls;
        readyLabel.hidden = !hideControls;
        
        if (hideControls) {
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            displayTitle.frame = CGRectMake(20, 20, 280, 20);
        }
        else {
            cell.accessoryType = UITableViewCellAccessoryNone;
            displayTitle.frame = CGRectMake(20, 15, 280, 20);
        }
        
        startPauseButtonImageName = @"play-25";
    }
    else {
        progressView.hidden = NO;
        progressView.progress = fdi.downloadProgress;
        
        stopButton.enabled = YES;
        
        startPauseButtonImageName = @"pause-25";
    }
    
    [startPauseButton setImage:[UIImage imageNamed:startPauseButtonImageName] forState:UIControlStateNormal];
    
    return cell;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 60.0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 0.01;
}

#pragma mark - Download-Related Actions

- (void)downloadSingleFile:(YTPFileDownloadInfo *)fdi {
    if (!fdi.isDownloading) {
        if (fdi.taskIdentifier == -1) {
            // If the taskIdentifier property of the fdi object has value -1, then create a new task
            // providing the appropriate URL as the download source.
            fdi.downloadTask = [self.session downloadTaskWithURL:[NSURL URLWithString:fdi.downloadSource]];
            
            // Keep the new task identifier.
            fdi.taskIdentifier = fdi.downloadTask.taskIdentifier;
            
            // Start the task.
            [fdi.downloadTask resume];
        }
        else {
            // Create a new download task, which will use the stored resume data.
            fdi.downloadTask = [self.session downloadTaskWithResumeData:fdi.taskResumeData];
            [fdi.downloadTask resume];
            
            // Keep the new download task identifier.
            fdi.taskIdentifier = fdi.downloadTask.taskIdentifier;
        }
    }
    
    fdi.isDownloading = YES;
    
    [self.arrFileDownloadData insertObject:fdi atIndex:0];
    self.recentVideos = [[YTPSQLiteManager sharedManager] recentVideos];
    
    [self.tableView reloadData];
}

- (IBAction)startOrPauseDownloadingSingleFile:(id)sender {
    UITableViewCell *containerCell = (UITableViewCell *)[sender superview];

    while (![containerCell isKindOfClass:[UITableViewCell class]]) {
        containerCell = (UITableViewCell *)[containerCell superview];
    }
    
    NSIndexPath *cellIndexPath = [self.tableView indexPathForCell:containerCell];
    int cellIndex = (int)cellIndexPath.row;
    
    YTPFileDownloadInfo *fdi = [self.arrFileDownloadData objectAtIndex:cellIndex];
    
    if (!fdi.isDownloading) {
        // Create a new task, but check whether it should be created using a URL or resume data.
        if (fdi.taskIdentifier == -1) {
            // If the taskIdentifier property of the fdi object has value -1, then create a new task
            // providing the appropriate URL as the download source.
            fdi.downloadTask = [self.session downloadTaskWithURL:[NSURL URLWithString:fdi.downloadSource]];
            
            // Keep the new task identifier.
            fdi.taskIdentifier = fdi.downloadTask.taskIdentifier;
            
            // Start the task.
            [fdi.downloadTask resume];
        }
        else{
            // Create a new download task, which will use the stored resume data.
            fdi.downloadTask = [self.session downloadTaskWithResumeData:fdi.taskResumeData];
            [fdi.downloadTask resume];
            
            // Keep the new download task identifier.
            fdi.taskIdentifier = fdi.downloadTask.taskIdentifier;
        }
    }
    else {
        // Pause the task by canceling it and storing the resume data.
        [fdi.downloadTask cancelByProducingResumeData:^(NSData *resumeData) {
            if (resumeData != nil) {
                fdi.taskResumeData = [[NSData alloc] initWithData:resumeData];
            }
        }];
    }
    
    // Change the isDownloading property value.
    fdi.isDownloading = !fdi.isDownloading;
    
    // Reload the table view.
    [self.tableView reloadRowsAtIndexPaths:@[cellIndexPath] withRowAnimation:UITableViewRowAnimationNone];
}

- (void)stopDownloading:(id)sender {
    UITableViewCell *containerCell = (UITableViewCell *)[sender superview];
    
    while (![containerCell isKindOfClass:[UITableViewCell class]]) {
        containerCell = (UITableViewCell *)[containerCell superview];
    }
    
    NSIndexPath *cellIndexPath = [self.tableView indexPathForCell:containerCell];
    int cellIndex = (int)cellIndexPath.row;
    
    YTPFileDownloadInfo *fdi = [self.arrFileDownloadData objectAtIndex:cellIndex];
    
    [fdi.downloadTask cancel];
    fdi.isDownloading = NO;
    fdi.taskIdentifier = -1;
    fdi.downloadProgress = 0.0;
    
    [self.tableView reloadRowsAtIndexPaths:@[cellIndexPath] withRowAnimation:UITableViewRowAnimationNone];
}

- (void)startAllDownloads:(id)sender {
    for (YTPFileDownloadInfo *fdi in self.arrFileDownloadData) {
        if (!fdi.isDownloading) {
            // Check if should create a new download task using a URL, or using resume data.
            if (fdi.taskIdentifier == -1) {
                fdi.downloadTask = [self.session downloadTaskWithURL:[NSURL URLWithString:fdi.downloadSource]];
            }
            else{
                fdi.downloadTask = [self.session downloadTaskWithResumeData:fdi.taskResumeData];
            }
            
            // Keep the new taskIdentifier.
            fdi.taskIdentifier = fdi.downloadTask.taskIdentifier;
            
            // Start the download.
            [fdi.downloadTask resume];
            
            // Indicate for each file that is being downloaded.
            fdi.isDownloading = YES;
        }
    }
    
    [self.tableView reloadData];
}

- (void)stopAllDownloads:(id)sender {
    for (YTPFileDownloadInfo *fdi in self.arrFileDownloadData) {
        if (fdi.isDownloading) {
            // Cancel the task.
            [fdi.downloadTask cancel];
            
            // Change all related properties.
            fdi.isDownloading = NO;
            fdi.taskIdentifier = -1;
            fdi.downloadProgress = 0.0;
            fdi.downloadTask = nil;
        }
    }
    
    [self.tableView reloadData];
}

#pragma mark - NSURLSessionDelegate

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location {
    
    NSError *error;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    int index = [self getFileDownloadInfoIndexWithTaskIdentifier:downloadTask.taskIdentifier];
    YTPFileDownloadInfo *fdi = [self.arrFileDownloadData objectAtIndex:index];
    
    NSString *destinationFilename = [NSString stringWithFormat:@"%@.mp4", fdi.fileTitle];
    NSURL *destinationURL = [self.docDirectoryURL URLByAppendingPathComponent:destinationFilename];
    
    if ([fileManager fileExistsAtPath:[destinationURL path]]) {
        [fileManager removeItemAtURL:destinationURL error:nil];
    }
    
    BOOL success = [fileManager copyItemAtURL:location
                                        toURL:destinationURL
                                        error:&error];
    
    if (success) {
        int index = [self getFileDownloadInfoIndexWithTaskIdentifier:downloadTask.taskIdentifier];
        YTPFileDownloadInfo *fdi = [self.arrFileDownloadData objectAtIndex:index];
        
        fdi.isDownloading = NO;
        fdi.downloadComplete = YES;
        fdi.taskIdentifier = -1;
        
        // In case there is any resume data stored in the fdi object, just make it nil.
        fdi.taskResumeData = nil;
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            // Reload the respective table view row using the main thread.
            [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:index inSection:0]]
                                 withRowAnimation:UITableViewRowAnimationNone];
            
        }];
        
        // Mark the video as completed!  :)
        [[YTPSQLiteManager sharedManager] markVideoAsComplete:fdi.fileTitle];
    }
    else{
        NSLog(@"Unable to copy temp file. Error: %@", [error localizedDescription]);
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    if (error != nil) {
        NSLog(@"Download completed with error: %@", [error localizedDescription]);
    }
    else{
        NSLog(@"Download finished successfully.");
    }
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    
    if (totalBytesExpectedToWrite == NSURLSessionTransferSizeUnknown) {
        NSLog(@"Unknown transfer size");
    }
    else{
        int index = [self getFileDownloadInfoIndexWithTaskIdentifier:downloadTask.taskIdentifier];
        YTPFileDownloadInfo *fdi = [self.arrFileDownloadData objectAtIndex:index];
      
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            fdi.downloadProgress = (double)totalBytesWritten / (double)totalBytesExpectedToWrite;
              
            YTPTableViewCell *cell = (YTPTableViewCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
            UIProgressView *progressView = cell.progressView;
            progressView.progress = fdi.downloadProgress;
        }];
    }
}

- (void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session {
    YTPAppDelegate *appDelegate = [UIApplication sharedApplication].delegate;
    
    [self.session getTasksWithCompletionHandler:^(NSArray *dataTasks, NSArray *uploadTasks, NSArray *downloadTasks) {
        
        if ([downloadTasks count] == 0) {
            if (appDelegate.backgroundTransferCompletionHandler != nil) {
                // Copy locally the completion handler.
                void(^completionHandler)() = appDelegate.backgroundTransferCompletionHandler;
                
                // Make nil the backgroundTransferCompletionHandler.
                appDelegate.backgroundTransferCompletionHandler = nil;
                
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    // Call the completion handler to tell the system that there are no other background transfers.
                    completionHandler();
                    
                    // Show a local notification when all downloads are over.
                    UILocalNotification *localNotification = [[UILocalNotification alloc] init];
                    localNotification.alertBody = @"All files have been downloaded!";
                    [[UIApplication sharedApplication] presentLocalNotificationNow:localNotification];
                }];
            }
        }
    }];
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (!(buttonIndex == [alertView cancelButtonIndex])) {
        // Download New YouTube Video
        [self submitYouTubeURL];
    }
}

#pragma mark - Orientations

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

@end
