//
//  PhotosCDTVC.m
//  Photomania
//
//  Created by Kevin on 10/06/2014.
//  Copyright (c) 2014 ___kevinPitolin___. All rights reserved.
//

#import "PhotosCDTVC.h"
#import "Photo.h"
#import "ImageViewController.h"

@implementation PhotosCDTVC
-(UITableViewCell *)tableView: (UITableView *) tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    UITableViewCell * cell = [self.tableView dequeueReusableCellWithIdentifier:@"Photo Cell"];
    Photo * photo = [self.fetchedResultsController objectAtIndexPath:indexPath];
    cell.textLabel.text = photo.title;
    cell.detailTextLabel.text = photo.subtitle;
    
    return cell;
}
#pragma mark - Navigation

- (void) prepareViewController:(id)vc forSegue:(NSString *)segueIdentifier fromIndexPath:(NSIndexPath *)index{
    
    dispatch_queue_t load = dispatch_queue_create("score load", NULL);
    dispatch_async(load, ^{
    Photo * photo = [self.fetchedResultsController objectAtIndexPath:index];
    if ([vc isKindOfClass:[ImageViewController class]]){
            //prepare vc
        ImageViewController * ivc = (ImageViewController * )vc;
        ivc.imageURL  = [NSURL URLWithString:photo.imageURL];
        ivc.title = photo.title;
            
        
    }
    });
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

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    id detailVc = [self.splitViewController.viewControllers lastObject];
    
    if ([detailVc isKindOfClass:[UINavigationController class]]){
        detailVc = [((UINavigationController *)detailVc).viewControllers firstObject];
        [self prepareViewController:detailVc
                           forSegue:nil
                      fromIndexPath:indexPath];
    }
}

@end
