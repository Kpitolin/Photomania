//
//  Photo+Flickr.h
//  Photomania
//
//  Created by Kevin on 03/06/2014.
//  Copyright (c) 2014 ___kevinPitolin___. All rights reserved.
//

#import "Photo.h"

@interface Photo (Flickr)

+(Photo *)photoWithFlickrInfo:(NSDictionary *)photoDictionnary inManagedObjectContext:(NSManagedObjectContext *)context;


+ (void) loadPhotosFromFlickrArray:(NSArray *)photos intoManagedObjectContext: (NSManagedObjectContext *)context ;// of Flickr Dictionnary

    


@end
