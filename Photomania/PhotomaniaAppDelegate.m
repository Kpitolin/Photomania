//
//  AppDelegate.m
//  Photomania
//
//  Created by Kevin on 03/06/2014.
//  Copyright (c) 2014 ___kevinPitolin___. All rights reserved.
//

#import "PhotomaniaAppDelegate.h"
#import "FlickrFetcher.h"
// Sort of the listener of the app lifecycle : it knows the actual state of your application

@interface PhotomaniaAppDelegate () <NSURLSessionDownloadDelegate>
@property (copy, nonatomic) void (^flickrDownloadBackgroudSessionCompletionHandler)();
@property (nonatomic, strong) NSURLSession * flickrDownloadSession;
@property (nonatomic , strong) NSTimer * flickrForegroundFetchTimer;
//@property  (nonatomic,strong ) ;
@end



@implementation PhotomaniaAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    
    // Here do UIManagedDocument things
    
    
    [self startFlickrFetch]; // It's gonna start the Flickr fetch as soon as we launch
    
    return YES;
}

- (void) startFlickrFetch
{
    [self flickrDownloadSessionCompletionHandler:^ (NSArray * dataTasks, NSArray * uploadTasks, NSArray * downloadTasks){
        
        if (![downloadTasks count]){
            NSURLSessionDownloadTask * task = [self.flickrDownloadSession downloadTaskWithURL:[FlickrFetcher URLforRecentGeoreferencedPhotos]];
            task.taskDescription = FLICKR_FETCH;
            [task resume]; // Really start the thing
        } else{
            for (NSURLSessionDownloadTask * task in downloadTasks) [task resume];
                
            
        }
       
        
    }];
}
							
-(NSURLSession *) flickrDownloadSession { // It's the session we will use to fecth data in the background
    
    if(!_flickrDownloadSession){
        static dispatch_once_t onceToken ; // Here I think we just create a thread to download the data throughout
        dispatch_once(&onceToken, ^{
            NSURLSessionConfiguration * urlSessionConfig = [NSURLSessionConfiguration backgroundSessionConfiguration:FLICKR_FETCH];
        // urlSessionConfig.allowsCellularAccess = NO;
            _flickrDownloadSession = [NSURLSession sessionWithConfiguration:urlSessionConfig delegate:self delegateQueue:nil]; // the delegate is gonna be called
                                                                                                                               // when the completionHandler finish his tasks
        });
    }
    
    
    return _flickrDownloadSession;
}


#pragma - mark NSURLSessionDownloadDelegate
/* Sent when a download task that has completed a download.  The delegate should
 * copy or move the file at the given location to a new location as it will be
 * removed when the delegate message returns. URLSession:task:didCompleteWithError: will
 * still be called.
 */
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL *)location
{
    if ([downloadTask.taskDescription = FLICKR_FETCH]){
        NSManagedObjectContext * context = self.photoDatabaseContext;
        
        if (context){
            NSArray * photos = [self flickrPhotosatURL:location]; // Array of the photos we're gonna download from Flickr
            [context performBlock ^{
                [Photo loadPhotosWithFlickrDataArray:photos intoManagedObjectContext:context]; // Actually dowload the photos to fill the array
                [context save: NULL];
            }];
        }
    } else{
        [self flickrDowloadTaskMightBeComplete];
    }
}

/* Sent periodically to notify the delegate of download progress. */
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
      didWriteData:(int64_t)bytesWritten
 totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{
    
}

/* Sent when a download has been resumed. If a download failed with an
 * error, the -userInfo dictionary of the error will contain an
 * NSURLSessionDownloadTaskResumeData key, whose value is the resume
 * data.
 */
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
 didResumeAtOffset:(int64_t)fileOffset
expectedTotalBytes:(int64_t)expectedTotalBytes
{
}




@end
