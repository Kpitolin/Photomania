//
//  FlickrHelper.m
//  Photomania
//
//  Created by Kevin on 05/06/2014.
//  Copyright (c) 2014 ___kevinPitolin___. All rights reserved.
//

#import "FlickrHelper.h"

@implementation FlickrHelper




#pragma mark  - Block method

/*
+ (void)openDocument:(NSString *)nameOfDocument usingBlock:(void (^)())completionBlock
{
    // Try to retrieve the relevant UIManagedDocument from managedDocumentDictionary
    UIManagedDocument *doc = nil;
    
    // Get URL for this vacation -> "<Documents Directory>/<nameOfDocument>"
    NSURL *url = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
    url = [url URLByAppendingPathComponent:nameOfDocument];
    
    // If UIManagedObject was not retrieved, create it
    if (!doc) {
        
        // Create UIManagedDocument with this URL
        doc = [[UIManagedDocument alloc] initWithFileURL:url];
        
        // Add to managedDocumentDictionary : no need for any dictionnary here
      //  [managedDocumentDictionary setObject:doc forKey:nameOfDocument];
    }
    
    // If document exists on disk...
    
 
    }
    
}
 */





#pragma mark  - Simple method








/*
 - (void)saveContext:(NSManagedObjectContext *)managedObjectContext
 {
 NSError *error = nil;
 if (managedObjectContext != nil) {
 if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
 // Replace this implementation with code to handle the error appropriately.
 // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
 NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
 abort();
 }
 }
 }
 
 // Returns the managed object context for the application.
 // If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
 - (NSManagedObjectContext *)createMainQueueManagedObjectContext
 {
 NSManagedObjectContext *managedObjectContext = nil;
 NSPersistentStoreCoordinator *coordinator = [self createPersistentStoreCoordinator];
 if (coordinator != nil) {
 managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
 [managedObjectContext setPersistentStoreCoordinator:coordinator];
 }
 return managedObjectContext;
 }
 
 
 */

@end
