//
//  Photographer+Create.h
//  Photomania
//
//  Created by Kevin on 03/06/2014.
//  Copyright (c) 2014 ___kevinPitolin___. All rights reserved.
//

#import "Photographer.h"
#import "FlickrFetcher.h"

@interface Photographer (Create)


+(Photographer *) photographerWithName:(NSString *)name inManagedObjectContext: (NSManagedObjectContext *) context ;
@end
