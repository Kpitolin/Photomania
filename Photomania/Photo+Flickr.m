//
//  Photo+Flickr.m
//  Photomania
//
//  Created by Kevin on 03/06/2014.
//  Copyright (c) 2014 ___kevinPitolin___. All rights reserved.
//

#import "Photo+Flickr.h"
#import "FlickrFetcher.h"
#import "Photographer+Create.h"
@implementation Photo (Flickr)


// WATCH OUT  : HERE INSTANCE VARIABLES ARE FORBIDDEN !!!

+(Photo *)photoWithFlickrInfo:(NSDictionary *)photoDictionnary inManagedObjectContext:(NSManagedObjectContext *)context;
{
    
    Photo * photo = nil;
    
    
    
    NSString * unique  = photoDictionnary [FLICKR_PHOTO_ID] ;
    NSFetchRequest * request = [NSFetchRequest fetchRequestWithEntityName:@"Photo"];

    request.predicate = [NSPredicate predicateWithFormat:@"uniqueId = %@",unique ];
    NSError * error;
    NSArray * matches = [ context executeFetchRequest:request error: &error]; //error here
    
    if (!matches  ||  error  || ([matches count] > 1)){
        
        // HANDLE THE ERRORS
        
    }else if ([matches count]){
        photo =  [matches firstObject];
    }else{
        photo = [NSEntityDescription insertNewObjectForEntityForName:@"Photo" inManagedObjectContext:context];
        
        photo.uniqueId = unique ;
        photo.title  = [photoDictionnary valueForKeyPath:FLICKR_PHOTO_TITLE];
        photo.subtitle  = [photoDictionnary valueForKeyPath:FLICKR_PHOTO_DESCRIPTION];
        photo.imageURL = [[FlickrFetcher URLforPhoto:photoDictionnary format:FlickrPhotoFormatLarge] absoluteString ];
        NSString * photographerName = [photoDictionnary valueForKeyPath:FLICKR_PHOTO_OWNER];
        photo.whoTook = [Photographer photographerWithName:photographerName inManagedObjectContext:context] ;
        
        
        
    }
    
    return photo;
}

+ (void) loadPhotosFromFlickrArray:(NSArray *)photos intoManagedObjectContext: (NSManagedObjectContext *)context ;// of Flickr Dictionnary
{
    for (NSDictionary * photos in photos)
    {
        [self photoWithFlickrInfo:photos inManagedObjectContext:context]; // we just insert it in the database  and we don't take the return : perfectly fine and legal
    }
}








@end
