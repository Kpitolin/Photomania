//
//  AppDelegate.m
//  Photomania
//
//  Created by Kevin on 03/06/2014.
//  Copyright (c) 2014 ___kevinPitolin___. All rights reserved.
//

#import "PhotomaniaAppDelegate.h"
#import "FlickrFetcher.h"
#import "FlickrHelper.h"
#import "Photo+Flickr.h"
// Sort of the listener of the app lifecycle : it knows the actual state of your application

@interface PhotomaniaAppDelegate () <NSURLSessionDownloadDelegate>
@property (copy, nonatomic) void (^flickrDownloadBackgroundURLSessionCompletionHandler)();
@property (nonatomic, strong) NSURLSession * flickrDownloadSession;
@property (nonatomic , strong) NSTimer * flickrForegroundFetchTimer;
@property (strong, nonatomic) NSManagedObjectContext *photoDatabaseContext;
@end

// name of the Flickr fetching background download session
#define FLICKR_FETCH @"Flickr Just Uploaded Fetch"
#define NAME_OF_DATABASE @"FlickrDatabase"
@implementation PhotomaniaAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    
    
    // Here I probably should get the ObjectManagedContext from the UIManagedDocument
    self.photoDatabaseContext =  [FlickrHelper managedDocument].managedObjectContext;
    
    [self startFlickrFetch]; // It's gonna start the Flickr fetch as soon as we launch
    
    return YES;
}




- (void) startFlickrFetch
{
    [self.flickrDownloadSession getTasksWithCompletionHandler:^ (NSArray * dataTasks, NSArray * uploadTasks, NSArray * downloadTasks){
        
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
// gets the Flickr photo dictionaries out of the url and puts them into Core Data
// this was moved here after lecture to give you an example of how to declare a method that takes a block as an argument
// and because we now do this both as part of our background session delegate handler and when background fetch happens

- (void)loadFlickrPhotosFromLocalURL:(NSURL *)localFile
                         intoContext:(NSManagedObjectContext *)context
                 andThenExecuteBlock:(void(^)())whenDone
{
    if (context) {
        NSArray *photos = [self flickrPhotosAtURL:localFile];
        [context performBlock:^{
            [Photo loadPhotosFromFlickrArray:photos intoManagedObjectContext:context];
            [context save:NULL]; // NOT NECESSARY if this is a UIManagedDocument's context
            if (whenDone) whenDone(); // if the block exist, execute it
        }];
    } else {
        if (whenDone) whenDone(); // idem even if the context doesn't exist
    }
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
    // we shouldn't assume we're the only downloading going on ...
    // we gave a name to the taskDescription earlier (in start Flickr fetch)
    if ([downloadTask.taskDescription isEqualToString:FLICKR_FETCH]) {
        // ... but if this is the Flickr fetching, then process the returned data
        [self loadFlickrPhotosFromLocalURL:location
                               intoContext:self.photoDatabaseContext
                       andThenExecuteBlock:^{
                           [self flickrDownloadTasksMightBeComplete];
                       }
         ];
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

-(NSArray *) flickrPhotosAtURL:(NSURL *)url
{
    
        NSData * jsonResults = [NSData dataWithContentsOfURL: url];
        NSDictionary * propertyListResults =  [NSJSONSerialization JSONObjectWithData:jsonResults options:0 error:NULL]; // Transform the JSON data into a dictionnary
        NSArray *photos = [ propertyListResults valueForKeyPath:FLICKR_RESULTS_PHOTOS];
            
    
    return photos;
}

// this is "might" in case some day we have multiple downloads going on at once

- (void)flickrDownloadTasksMightBeComplete
{
    if (self.flickrDownloadBackgroundURLSessionCompletionHandler) {
        [self.flickrDownloadSession getTasksWithCompletionHandler:^(NSArray *dataTasks, NSArray *uploadTasks, NSArray *downloadTasks) {
            // we're doing this check for other downloads just to be theoretically "correct"
            //  but we don't actually need it (since we only ever fire off one download task at a time)
            // in addition, note that getTasksWithCompletionHandler: is ASYNCHRONOUS
            //  so we must check again when the block executes if the handler is still not nil
            //  (another thread might have sent it already in a multiple-tasks-at-once implementation)
            if (![downloadTasks count]) {  // any more Flickr downloads left?
                // nope, then invoke flickrDownloadBackgroundURLSessionCompletionHandler (if it's still not nil)
                void (^completionHandler)() = self.flickrDownloadBackgroundURLSessionCompletionHandler;
                self.flickrDownloadBackgroundURLSessionCompletionHandler = nil;
                if (completionHandler) {
                    completionHandler();
                }
            } // else other downloads going, so let them call this method when they finish
        }];
    }
    
}




@end
