//
//  PhotographersCDTVC.m
//  Photomania
//
//  Created by Kevin on 04/06/2014.
//  Copyright (c) 2014 ___kevinPitolin___. All rights reserved.
//

#import "PhotographersCDTVC.h"
#import "Photographer.h"
#import "FlickrHelper.h"
#import "PhotosByPhotographerCDTVC.h"
@implementation PhotographersCDTVC
- (void)awakeFromNib
{
    self.managedObjectContext = [FlickrHelper managedDocument].managedObjectContext;

}
- (void) setManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
{
    _managedObjectContext = self.managedObjectContext ; // here I really wanna get this managedObjectContext !!
    
    NSFetchRequest * request =  [NSFetchRequest fetchRequestWithEntityName:@"Photographer"];
    request.predicate = nil; // Here I just want all of them
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"name"
                                                              ascending:YES
                                                               selector:@selector(localizedStandardCompare:)]];
    // request.fetchLimit = 100 ;
    self.fetchedResultsController = [[ NSFetchedResultsController alloc] initWithFetchRequest:request
                                                                         managedObjectContext:managedObjectContext
                                                                           sectionNameKeyPath:nil cacheName:nil];
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
