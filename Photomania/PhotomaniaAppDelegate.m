//
//  AppDelegate.m
//  Photomania
//
//  Created by Kevin on 03/06/2014.
//  Copyright (c) 2014 ___kevinPitolin___. All rights reserved.
//

#import "PhotomaniaAppDelegate.h"
#import "FlickrFetcher.h"
#import "Photo+Flickr.h"
#import "PhotoDatabaseAvailability.h"

// Sort of the listener of the app lifecycle : it knows the actual state of your application

@interface PhotomaniaAppDelegate () <NSURLSessionDownloadDelegate>
@property (copy, nonatomic) void (^flickrDownloadBackgroundURLSessionCompletionHandler)();
@property (nonatomic, strong) NSURLSession * flickrDownloadSession;
@property (nonatomic , strong) NSTimer * flickrForegroundFetchTimer;
@property ( strong, nonatomic) NSManagedObjectContext *photoDatabaseContext;
@property ( strong, nonatomic) UIManagedDocument *managedDocument;


@end


// name of the Flickr fetching background download session
#define FLICKR_FETCH @"Flickr Just Uploaded Fetch"

// how often (in seconds) we fetch new photos if we are in the foreground
#define FOREGROUND_FLICKR_FETCH_INTERVAL (20*60)

// how long we'll wait for a Flickr fetch to return when we're in the background
#define BACKGROUND_FLICKR_FETCH_TIMEOUT (10)


#define NAME_OF_DATABASE @"FlickrDatabase"

@implementation PhotomaniaAppDelegate



#pragma mark - Core Data stack

// Returns the managed object context for the application.
// If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
-(void)createManagedDocument
{
    UIManagedDocument * managedDocument = nil;
    
    
    
    // url is "<Documents Directory>/<FlickrDatabase>"
    NSFileManager* fileManager = [NSFileManager defaultManager];
    NSURL * documentDirectory = [[fileManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] firstObject];
    NSString  *documentName = NAME_OF_DATABASE;
    
    NSURL * url = [documentDirectory URLByAppendingPathComponent:documentName];
    // Create the instance lazily upon the first request.
    if (self.managedDocument == nil) {
        
        managedDocument = [[UIManagedDocument alloc] initWithFileURL:url];
        self.managedDocument = managedDocument;
    }
    
    
    
    NSLog(@"SharedDocument: %@", managedDocument);
    
    
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:[url path]])
    {
        [self.managedDocument openWithCompletionHandler:^(BOOL success)
        {
            
            if (success) {
                // Do something here when the managedDocument is opened
                [self documentIsReady];
            } else{
                NSLog(@" Couldn't open document at URL : %@",url);
            }
        }];
        
    } else {
        
        [self.managedDocument  saveToURL:url
                    forSaveOperation:UIDocumentSaveForCreating
                   completionHandler:^(BOOL success)
         {
             
             
             if (success) {
                 // Do something here when the managedDocument is created
                 [self documentIsReady];
             } else{
                 NSLog(@" Couldn't create document at URL :%@",url);
                 
             }
             
             
         }];
        
        
    }
    
    
}


-(void)documentIsReady{
    
    
    if (self.managedDocument.documentState == UIDocumentStateNormal)
    {
        self.photoDatabaseContext = self.managedDocument.managedObjectContext;
        NSLog(@"document successfully opened");
      
        
        
        
        
    }else if (self.managedDocument.documentState == UIDocumentStateClosed){
        NSLog(@"document closed");
        [self.managedDocument openWithCompletionHandler:^(BOOL success)
         {
             
             if (success) {
                 // Do something here when the managedDocument is opened
                 [self documentIsReady];
             } else{
                 NSLog(@"Couldn't open document");
             }
             
         }];
        
        
    }
}
// this is called occasionally by the system WHEN WE ARE NOT THE FOREGROUND APPLICATION
// in fact, it will LAUNCH US if necessary to call this method
// the system has lots of smarts about when to do this, but it is entirely opaque to us


// I just understood that it allows us (when iOs wants to) to fetch Flickr data;  the task description is still FLICKR_FETCH ? I don't think so because we create a new task and we don't set it
- (void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    // in lecture, we relied on our background flickrDownloadSession to do the fetch by calling [self startFlickrFetch]
    // that was easy to code up, but pretty weak in terms of how much it will actually fetch (maybe almost never)
    // that's because there's no guarantee that we'll be allowed to start that discretionary fetcher when we're in the background
    // so let's simply make a non-discretionary, non-background-session fetch here
    // we don't want it to take too long because the system will start to lose faith in us as a background fetcher and stop calling this as much
    // so we'll limit the fetch to BACKGROUND_FETCH_TIMEOUT seconds (also we won't use valuable cellular data)
    
    if (self.photoDatabaseContext) {
        NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration ephemeralSessionConfiguration];
        sessionConfig.allowsCellularAccess = NO;
        sessionConfig.timeoutIntervalForRequest = BACKGROUND_FLICKR_FETCH_TIMEOUT; // want to be a good background citizen!
        NSURLSession *session = [NSURLSession sessionWithConfiguration:sessionConfig];
        NSURLRequest *request = [[NSURLRequest alloc] initWithURL:[FlickrFetcher URLforRecentGeoreferencedPhotos]];
        NSURLSessionDownloadTask *task = [session downloadTaskWithRequest:request
                                                        completionHandler:^(NSURL *localFile, NSURLResponse *response, NSError *error) {
                                                            if (error) {
                                                                NSLog(@"Flickr background fetch failed: %@", error.localizedDescription);
                                                                completionHandler(UIBackgroundFetchResultNoData);
                                                            } else {
                                                                [self loadFlickrPhotosFromLocalURL:localFile
                                                                                       intoContext:self.photoDatabaseContext
                                                                               andThenExecuteBlock:^{
                                                                                   completionHandler(UIBackgroundFetchResultNewData);
                                                                               }
                                                                 ];
                                                            }
                                                        }];
        [task resume];
    } else {
        completionHandler(UIBackgroundFetchResultNoData); // no app-switcher update if no database!  :  it's executed if there's no database context
    }
}
#pragma mark - Database Context

// we do some stuff when our Photo database's context becomes available
// we kick off our foreground NSTimer so that we are fetching every once in a while in the foreground
// we post a notification to let others know the context is available
- (void)setPhotoDatabaseContext:(NSManagedObjectContext *)photoDatabaseContext
{
    _photoDatabaseContext = photoDatabaseContext;
    
    // every time the context changes, we'll restart our timer
    // so kill (invalidate) the current one
    // (we didn't get to this line of code in lecture, sorry!)
    [self.flickrForegroundFetchTimer invalidate];
    self.flickrForegroundFetchTimer = nil;
    
    if (self.photoDatabaseContext)
    {
        // this timer will fire only when we are in the foreground
        self.flickrForegroundFetchTimer = [NSTimer scheduledTimerWithTimeInterval:FOREGROUND_FLICKR_FETCH_INTERVAL
                                                                           target:self
                                                                         selector:@selector(startFlickrFetch:) // every time it begin to count, it calls the method startFlickrFetch
                                                                         userInfo:nil
                                                                          repeats:YES];
    }
    
    // let everyone who might be interested know this context is available
    // this happens very early in the running of our application
    // it would make NO SENSE to listen to this radio station in a View Controller that was segued to, for example : why ?
    // (but that's okay because a segued-to View Controller would presumably be "prepared" by being given a context to work in)
    NSDictionary *userInfo = self.photoDatabaseContext ? @{ PhotoDatabaseAvailabilityContext : self.photoDatabaseContext } : nil;
    [[NSNotificationCenter defaultCenter] postNotificationName:PhotoDatabaseAvailabilityNotification
                                                        object:self
                                                      userInfo:userInfo];
}


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    [[UIApplication sharedApplication] setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];
    [self createManagedDocument];
    
    // Here I probably should get the ObjectManagedContext from the UIManagedDocument
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

- (void)startFlickrFetch:(NSTimer *)timer // NSTimer target/action always takes an NSTimer as an argument : it permits to call the startFlickrFetch when the NSTimer starts
{
    [self startFlickrFetch];
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

//Required by protocol

/* Sent periodically to notify the delegate of download progress. */
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
      didWriteData:(int64_t)bytesWritten
 totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{
    
}
//Required by protocol

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
