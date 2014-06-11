//
//  PhotographersCDTVC.m
//  Photomania
//
//  Created by Kevin on 04/06/2014.
//  Copyright (c) 2014 ___kevinPitolin___. All rights reserved.
//

#import "PhotographersCDTVC.h"
#import "Photographer.h"
#import "PhotosByPhotographerCDTVC.h"
#import "PhotoDatabaseAvailability.h"
@interface PhotographersCDTVC ()
@property ( strong, nonatomic) UIManagedDocument *managedDocument;
@end


@implementation PhotographersCDTVC

#define NAME_OF_DATABASE @"FlickrDatabase"

#pragma mark - Core Data stack

// Returns the managed object context for the application.
// If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
-(UIManagedDocument *)createAndOpenManagedDocument
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
        _managedDocument = managedDocument;
    }
    
    
    
    NSLog(@"SharedDocument: %@", managedDocument);
    
    
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:[url path]])
    {
        [_managedDocument openWithCompletionHandler:^(BOOL success)
         {
             
             if (success) {
                 // Do something here when the managedDocument is opened
                 [self documentIsReady];
             } else{
                 NSLog(@" Couldn't open document at URL : %@",url);
             }
         }];
        
    } else {
        
        [_managedDocument  saveToURL:url
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
    return _managedDocument;
    
}


-(void)documentIsReady{
    
    
    if (self.managedDocument.documentState == UIDocumentStateNormal)
    {
        self.managedObjectContext = self.managedDocument.managedObjectContext;
        NSLog(@"document successfully opened");
        NSFetchRequest * request =  [NSFetchRequest fetchRequestWithEntityName:@"Photographer"];
        request.predicate = nil; // Here I just want all of them
        request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"name"
                                                                  ascending:YES
                                                                   selector:@selector(localizedStandardCompare:)]];
        // request.fetchLimit = 100 ;
        self.fetchedResultsController = [[ NSFetchedResultsController alloc] initWithFetchRequest:request
                                                                             managedObjectContext:self.managedObjectContext
                                                                               sectionNameKeyPath:nil cacheName:nil];
    
        
        
        
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

- (void)awakeFromNib
{
    [self createAndOpenManagedDocument];
}
- (void) setManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
{
    _managedObjectContext = managedObjectContext ; // here I really wanna get this managedObjectContext !!
}

// It specifies how to display the data in the cell :  where to put the title, the subtitle , etc
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell * cell = [self.tableView  dequeueReusableCellWithIdentifier:@"Photographer Cell"];
    Photographer * photographer  = [self.fetchedResultsController objectAtIndexPath:indexPath];
    cell.textLabel.text = photographer.name;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%d",(int)[photographer.photos count]];
    return cell;
}

#pragma mark - Navigation 

- (void) prepareViewController:(id)vc forSegue:(NSString *)segueIdentifier fromIndexPath:(NSIndexPath *)index{
    
    Photographer * photographer = [self.fetchedResultsController objectAtIndexPath:index];
    if ([vc isKindOfClass:[UIViewController class]]){
        if ([segueIdentifier isEqualToString:@"Show Photo by Photographer"]  || ![segueIdentifier length]){
            //prepare vc
            PhotosByPhotographerCDTVC * photoByPhotographer = (PhotosByPhotographerCDTVC *)vc;
            photoByPhotographer.photographer = photographer;
            
        }
    }
}

-(void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    NSIndexPath *index = nil;
    if ([sender isKindOfClass:[UITableViewCell class]]){
        index = [self.tableView indexPathForCell:sender];
    }
    [self prepareViewController:segue.destinationViewController
                       forSegue:segue.identifier
                  fromIndexPath:index];
}

-(void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath{
    id detailVc = [self.splitViewController.viewControllers lastObject];
    
    if ([detailVc isKindOfClass:[UINavigationController class]]){
        detailVc = [((UINavigationController *)detailVc).viewControllers firstObject];
        [self prepareViewController:detailVc
                           forSegue:nil
                      fromIndexPath:indexPath];
    }
}


@end
