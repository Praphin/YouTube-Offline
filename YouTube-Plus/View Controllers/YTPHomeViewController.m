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
                
                // Save the video metadata info into SQLite (@"Incomplete", will be changed to be "Complete" when the download is finished.).
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
        
        if (indexPath.row < self.arrFileDownloadData.count) {
            [self.arrFileDownloadData removeObjectAtIndex:indexPath.row];
        }
        if (indexPath.row < self.recentVideos.count) {
            [self.recentVideos removeObjectAtIndex:indexPath.row];
        }
        
        [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationLeft];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Update:
    self.recentVideos = [[YTPSQLiteManager sharedManager] recentVideos];
    
    // Index the exact video:
    YTPVideo *video = [self.recentVideos objectAtIndex:indexPath.row];
    
    if ([video.videoState isEqualToString:@"Complete"]) {
        // in iOS8  :)  555555...
        NSURL *destinationURL = [[[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject] URLByAppendingPathComponent:[NSString stringWithFormat:@"%@.mp4", video.videoPath]];
        
        // Use fileURLWithPath instead of URLWithString
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
    
    // Get the respective FileDownloadInfo object from the arrFileDownloadData array.
    YTPFileDownloadInfo *fdi = [self.arrFileDownloadData objectAtIndex:indexPath.row];
    
    // Get all cell's subviews.
    UILabel *displayedTitle = cell.displayTitle;
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
    
    // Set the file title.
    displayedTitle.text = fdi.fileName;
    
    // Depending on whether the current file is being downloaded or not, specify the status
    // of the progress bar and the couple of buttons on the cell.
    if (!fdi.isDownloading) {
        // Hide the progress view and disable the stop button.
        progressView.hidden = YES;
        stopButton.enabled = NO;
        
        // Set a flag value depending on the downloadComplete property of the fdi object.
        // Using it will be shown either the start and stop buttons, or the Ready label.
        BOOL hideControls = (fdi.downloadComplete) ? YES : NO;
        startPauseButton.hidden = hideControls;
        stopButton.hidden = hideControls;
        readyLabel.hidden = !hideControls;
        
        if (hideControls) {
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            displayedTitle.frame = CGRectMake(20, 20, 280, 20);
        }
        else {
            cell.accessoryType = UITableViewCellAccessoryNone;
            displayedTitle.frame = CGRectMake(20, 15, 280, 20);
        }
        
        startPauseButtonImageName = @"play-25";
    }
    else{
        // Show the progress view and update its progress, change the image of the start button so it shows
        // a pause icon, and enable the stop button.
        progressView.hidden = NO;
        progressView.progress = fdi.downloadProgress;
        
        stopButton.enabled = YES;
        
        startPauseButtonImageName = @"pause-25";
    }
    
    // Set the appropriate image to the start button.
    [startPauseButton setImage:[UIImage imageNamed:startPauseButtonImageName] forState:UIControlStateNormal];
    
    return cell;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 60.0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 0.01;
}

#pragma mark - IBActions

- (void)downloadSingleFile:(YTPFileDownloadInfo *)fdi {
    // The isDownloading property of the fdi object defines whether a downloading should be started
    // or be stopped.
    if (!fdi.isDownloading) {
        // This is the case where a download task should be started.
        
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
    
    // Change the isDownloading property value.
    fdi.isDownloading = YES;
    
    [self.arrFileDownloadData insertObject:fdi atIndex:0];
    self.recentVideos = [[YTPSQLiteManager sharedManager] recentVideos];
    
    [self.tableView reloadData];
}

- (IBAction)startOrPauseDownloadingSingleFile:(id)sender {
    // Check if the parent view of the sender button is a table view cell.
    UITableViewCell *containerCell = (UITableViewCell *)[sender superview];

    while (![containerCell isKindOfClass:[UITableViewCell class]]) {
        containerCell = (UITableViewCell *)[containerCell superview];
    }
    
    // Get the row (index) of the cell. We'll keep the index path as well, we'll need it later.
    NSIndexPath *cellIndexPath = [self.tableView indexPathForCell:containerCell];
    int cellIndex = (int)cellIndexPath.row;
    
    // Get the FileDownloadInfo object being at the cellIndex position of the array.
    YTPFileDownloadInfo *fdi = [self.arrFileDownloadData objectAtIndex:cellIndex];
    
    // The isDownloading property of the fdi object defines whether a downloading should be started
    // or be stopped.
    if (!fdi.isDownloading) {
        // This is the case where a download task should be started.
        
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
    else{
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


- (IBAction)stopDownloading:(id)sender {
    // Check if the parent view of the sender button is a table view cell.
    UITableViewCell *containerCell = (UITableViewCell *)[sender superview];
    
    while (![containerCell isKindOfClass:[UITableViewCell class]]) {
        containerCell = (UITableViewCell *)[containerCell superview];
    }
    
    // Get the row (index) of the cell. We'll keep the index path as well, we'll need it later.
    NSIndexPath *cellIndexPath = [self.tableView indexPathForCell:containerCell];
    int cellIndex = (int)cellIndexPath.row;
    
    // Get the FileDownloadInfo object being at the cellIndex position of the array.
    YTPFileDownloadInfo *fdi = [self.arrFileDownloadData objectAtIndex:cellIndex];
    
    // Cancel the task.
    [fdi.downloadTask cancel];
    
    // Change all related properties.
    fdi.isDownloading = NO;
    fdi.taskIdentifier = -1;
    fdi.downloadProgress = 0.0;
    
    // Reload the table view.
    [self.tableView reloadRowsAtIndexPaths:@[cellIndexPath] withRowAnimation:UITableViewRowAnimationNone];
}

- (IBAction)startAllDownloads:(id)sender {
    // Access all FileDownloadInfo objects using a loop.
    for (int i=0; i<[self.arrFileDownloadData count]; i++) {
        YTPFileDownloadInfo *fdi = [self.arrFileDownloadData objectAtIndex:i];
        
        // Check if a file is already being downloaded or not.
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
    
    // Reload the table view.
    [self.tableView reloadData];
}

- (IBAction)stopAllDownloads:(id)sender {
    // Access all FileDownloadInfo objects using a loop.
    for (int i=0; i<[self.arrFileDownloadData count]; i++) {
        YTPFileDownloadInfo *fdi = [self.arrFileDownloadData objectAtIndex:i];
        
        // Check if a file is being currently downloading.
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
    
    // Reload the table view.
    [self.tableView reloadData];
}

#pragma mark - NSURLSession Delegate method implementation

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
        // Change the flag values of the respective FileDownloadInfo object.
        int index = [self getFileDownloadInfoIndexWithTaskIdentifier:downloadTask.taskIdentifier];
        YTPFileDownloadInfo *fdi = [self.arrFileDownloadData objectAtIndex:index];
        
        fdi.isDownloading = NO;
        fdi.downloadComplete = YES;
        
        // Set the initial value to the taskIdentifier property of the fdi object,
        // so when the start button gets tapped again to start over the file download.
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
        // Locate the FileDownloadInfo object among all based on the taskIdentifier property of the task.
        int index = [self getFileDownloadInfoIndexWithTaskIdentifier:downloadTask.taskIdentifier];
        YTPFileDownloadInfo *fdi = [self.arrFileDownloadData objectAtIndex:index];
      
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            // Calculate the progress.
            fdi.downloadProgress = (double)totalBytesWritten / (double)totalBytesExpectedToWrite;
              
            // Get the progress view of the appropriate cell and update its progress.
            YTPTableViewCell *cell = (YTPTableViewCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
            UIProgressView *progressView = cell.progressView;
            progressView.progress = fdi.downloadProgress;
        }];
    }
}

- (void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session {
    YTPAppDelegate *appDelegate = [UIApplication sharedApplication].delegate;
    
    // Check if all download tasks have been finished.
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
