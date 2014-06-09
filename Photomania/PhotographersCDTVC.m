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
@implementation PhotographersCDTVC

- (void) setManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
{
    _managedObjectContext = managedObjectContext ;
    NSFetchRequest * request =  [NSFetchRequest fetchRequestWithEntityName:@"Photographer"];
    request.predicate = nil; // Here I just want all of them
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES selector:@selector(localizedStandardCompare:)]];
    // request.fetchLimit = 100 ;
    self.fetchedResultsController = [[ NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:managedObjectContext sectionNameKeyPath:nil cacheName:nil];
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



@end
